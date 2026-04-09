import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pushup_state.dart';

enum _Phase { up, down }

class PushUpCubit extends Cubit<PushUpState> {
  PushUpCubit({this.targetReps}) : super(const PushUpInitial());

  final int? targetReps;

  CameraController? _camera;
  PoseDetector? _detector;
  bool _processing = false;
  int _sensorOrientation = 0;

  int _lastSentMs = 0;
  static const int _minIntervalMs = 200; // ~5 fps detection

  // Counting — angle-based (elbow joint)
  _Phase _phase = _Phase.up;
  int _repCount = 0;
  static const double _armsUpAngle = 140.0;
  static const double _armsDownAngle = 100.0;

  Future<void> startSession() async {
    emit(const CameraLoading());
    try {
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
        ),
      );

      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _sensorOrientation = front.sensorOrientation;

      _camera = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();

      _phase = _Phase.up;
      _repCount = 0;

      emit(SessionActive(
        camera: _camera!,
        repCount: 0,
        poses: const [],
        imageWidth: _camera!.value.previewSize?.width.toInt() ?? 480,
        imageHeight: _camera!.value.previewSize?.height.toInt() ?? 640,
      ));

      await _camera!.startImageStream(_onCameraImage);
    } catch (e, st) {
      debugPrint('[PushUpCubit] startSession error: $e\n$st');
      emit(const PushUpInitial());
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_processing) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSentMs < _minIntervalMs) return;
    _lastSentMs = now;
    _processing = true;
    _processFrame(image).whenComplete(() => _processing = false);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_detector == null || state is! SessionActive) return;
    final current = state as SessionActive;

    try {
      final plane = image.planes[0];
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _sensorOrientationToRotation(_sensorOrientation),
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final poses = await _detector!.processImage(inputImage);

      String? feedback;
      List<DetectedPose> detectedPoses;

      if (poses.isEmpty) {
        feedback = 'Move into frame';
        detectedPoses = const [];
      } else {
        final landmarks = poses.first.landmarks.entries
            .map((e) => DetectedLandmark(
                  e.key,
                  e.value.x,
                  e.value.y,
                  e.value.likelihood,
                ))
            .toList();
        detectedPoses = [DetectedPose(landmarks)];

        final pose = detectedPoses.first;
        final elbowAngle = _avgElbowAngle(pose);

        if (elbowAngle == null) {
          feedback = 'Move into frame';
        } else {
          if (_phase == _Phase.up && elbowAngle < _armsDownAngle) {
            _phase = _Phase.down;
          } else if (_phase == _Phase.down && elbowAngle > _armsUpAngle) {
            _phase = _Phase.up;
            _repCount++;
            if (targetReps != null && _repCount >= targetReps!) {
              unawaited(stopSession(goalReached: true));
              return;
            }
          }
        }
      }

      if (state is SessionActive) {
        emit(current.copyWith(
          repCount: _repCount,
          feedback: feedback,
          clearFeedback: feedback == null,
          poses: detectedPoses,
          imageWidth: image.width,
          imageHeight: image.height,
        ));
      }
    } catch (e) {
      debugPrint('[PushUpCubit] _processFrame error: $e');
    }
  }

  double _angleDeg(
      double ax, double ay, double bx, double by, double cx, double cy) {
    final v1x = ax - bx, v1y = ay - by;
    final v2x = cx - bx, v2y = cy - by;
    final dot = v1x * v2x + v1y * v2y;
    final mag = math.sqrt(v1x * v1x + v1y * v1y) *
        math.sqrt(v2x * v2x + v2y * v2y);
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  double? _avgElbowAngle(DetectedPose pose) {
    final angles = <double>[];
    for (final side in [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    ]) {
      final s = pose.getLandmark(side[0]);
      final e = pose.getLandmark(side[1]);
      final w = pose.getLandmark(side[2]);
      if (s == null || e == null || w == null) continue;
      if (s.likelihood < 0.65 || e.likelihood < 0.65 || w.likelihood < 0.65) {
        continue;
      }
      angles.add(_angleDeg(s.x, s.y, e.x, e.y, w.x, w.y));
    }
    if (angles.isEmpty) return null;
    return angles.reduce((a, b) => a + b) / angles.length;
  }

  InputImageRotation _sensorOrientationToRotation(int orientation) {
    switch (orientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> stopSession({bool goalReached = false}) async {
    final count = _repCount;
    await _camera?.stopImageStream();
    await _camera?.dispose();
    _camera = null;
    _detector?.close();
    _detector = null;
    _processing = false;
    if (goalReached) {
      emit(SessionGoalReached(repCount: count));
    } else {
      emit(SessionComplete(repCount: count));
    }
  }

  @override
  Future<void> close() async {
    await _camera?.stopImageStream();
    await _camera?.dispose();
    _detector?.close();
    return super.close();
  }
}
