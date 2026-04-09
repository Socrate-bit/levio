import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pushup_state.dart';

enum _SquatPhase { up, down }

class SquatCubit extends Cubit<PushUpState> {
  SquatCubit({this.targetReps}) : super(const PushUpInitial());

  final int? targetReps;

  CameraController? _camera;
  PoseDetector? _detector;
  bool _processing = false;
  int _sensorOrientation = 0;

  int _lastSentMs = 0;
  static const int _minIntervalMs = 200;

  _SquatPhase _phase = _SquatPhase.up;
  int _repCount = 0;
  static const double _kneeDownAngle = 100.0;  // bent (squat down)
  static const double _kneeUpAngle = 160.0;    // straight (standing)

  Future<void> startSession() async {
    emit(const CameraLoading());
    try {
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
        ),
      );

      final cameras = await availableCameras();
      // Prefer back camera for squats (easier to see full body)
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _sensorOrientation = cam.sensorOrientation;

      _camera = CameraController(
        cam,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();

      _phase = _SquatPhase.up;
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
      debugPrint('[SquatCubit] startSession error: $e\n$st');
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
        final kneeAngle = _avgKneeAngle(pose);

        if (kneeAngle == null) {
          feedback = 'Move into frame';
        } else {
          if (_phase == _SquatPhase.up && kneeAngle < _kneeDownAngle) {
            _phase = _SquatPhase.down;
          } else if (_phase == _SquatPhase.down && kneeAngle > _kneeUpAngle) {
            _phase = _SquatPhase.up;
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
      debugPrint('[SquatCubit] _processFrame error: $e');
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

  double? _avgKneeAngle(DetectedPose pose) {
    final angles = <double>[];
    for (final side in [
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ]) {
      final h = pose.getLandmark(side[0]);
      final k = pose.getLandmark(side[1]);
      final a = pose.getLandmark(side[2]);
      if (h == null || k == null || a == null) continue;
      if (h.likelihood < 0.65 || k.likelihood < 0.65 || a.likelihood < 0.65) {
        continue;
      }
      angles.add(_angleDeg(h.x, h.y, k.x, k.y, a.x, a.y));
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
