import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pushup_state.dart';
import '../../../shared/services/sound_service.dart';
import '../../subscription/services/analytics_service.dart';

class PushUpCubit extends Cubit<PushUpState> {
  PushUpCubit({this.targetReps}) : super(const PushUpInitial());

  final int? targetReps;

  CameraController? _camera;
  PoseDetector? _detector;
  bool _processing = false;
  int _sensorOrientation = 0;

  int _lastSentMs = 0;
  // ~14 fps: the _processing guard self-limits to the device's real capability,
  // so this just stops us throttling below it. Higher rate is what lets rapid
  // reps register (a fast rep cycle is shorter than the old 200ms cap).
  static const int _minIntervalMs = 70;

  // Counting — angle-based hysteresis on the elbow joint. A rep = drop below
  // _downEnter (full depth) then rise back above _upEnter. The wide gap between
  // the two survives landmark jitter; _partial gates the "go deeper" hint.
  bool _started = false; // seen in the ready (up) position at least once
  bool _down = false; // currently in a descent (below _partial)
  bool _reachedDepth = false; // hit full depth during the current descent
  double? _smoothAngle; // EMA-smoothed elbow angle
  int _repCount = 0;
  static const double _upEnter = 160.0; // arms (near) extended
  static const double _downEnter = 110.0; // full depth
  static const double _partial = 140.0; // started going down
  static const double _emaAlpha = 0.6; // weight of the newest sample

  Future<void> startSession() async {
    emit(const CameraLoading());
    try {
      _detector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );

      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _sensorOrientation = front.sensorOrientation;

      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();
      // Lock the camera preview so it doesn't rotate when the device tilts.
      await _camera!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      _started = false;
      _down = false;
      _reachedDepth = false;
      _smoothAngle = null;
      _repCount = 0;

      emit(
        SessionActive(
          camera: _camera!,
          repCount: 0,
          poses: const [],
          imageWidth: _camera!.value.previewSize?.width.toInt() ?? 480,
          imageHeight: _camera!.value.previewSize?.height.toInt() ?? 640,
        ),
      );

      await _camera!.startImageStream(_onCameraImage);
    } catch (e, st) {
      debugPrint('[PushUpCubit] startSession error: $e\n$st');
      AnalyticsService.trackError('PushUpCubit.startSession', e, st);
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

      FeedbackKey? feedback;
      FeedbackType? feedbackType;
      List<DetectedPose> detectedPoses;

      if (poses.isEmpty) {
        feedback = FeedbackKey.moveIntoFrame;
        feedbackType = FeedbackType.warning;
        detectedPoses = const [];
      } else {
        final landmarks = poses.first.landmarks.entries
            .map(
              (e) => DetectedLandmark(
                e.key,
                e.value.x,
                e.value.y,
                e.value.likelihood,
              ),
            )
            .toList();
        detectedPoses = [DetectedPose(landmarks)];

        final pose = detectedPoses.first;
        final elbowAngles = _bothElbowAngles(pose);

        // Check landmark
        if (elbowAngles == null) {
          feedback = FeedbackKey.moveIntoFrame;
          _resetRep();
          feedbackType = FeedbackType.warning;
          detectedPoses = const [];
        } else {
          // Check position
          final wristBelowElbow = _isWristsBelowElbows(pose);
          if (!wristBelowElbow) {
            _resetRep();
            feedback = FeedbackKey.pushupPosition;
            feedbackType = FeedbackType.warning;
          } else {
            // Smoothed average elbow angle drives the hysteresis counter.
            final raw = (elbowAngles.$1 + elbowAngles.$2) / 2;
            _smoothAngle = _smoothAngle == null
                ? raw
                : _emaAlpha * raw + (1 - _emaAlpha) * _smoothAngle!;
            final angle = _smoothAngle!;

            if (!_started && angle >= _upEnter) {
              _started = true;
              feedback = FeedbackKey.startPushups;
              feedbackType = FeedbackType.positive;
            }

            if (_started) {
              if (!_down && angle < _partial) {
                _down = true;
                _reachedDepth = false;
              }
              if (_down) {
                if (angle < _downEnter) _reachedDepth = true;
                if (angle >= _upEnter) {
                  _down = false;
                  if (_reachedDepth) {
                    _repCount++;
                    feedback = FeedbackKey.keepGoing;
                    feedbackType = FeedbackType.positive;
                    unawaited(SoundService.instance.playRepBell());
                    if (targetReps != null && _repCount >= targetReps!) {
                      unawaited(stopSession(goalReached: true));
                      return;
                    }
                  } else {
                    feedback = FeedbackKey.pushupGoDeeper;
                    feedbackType = FeedbackType.warning;
                  }
                }
              }
            }
          }
        }
      }

      if (state is SessionActive) {
        emit(
          current.copyWith(
            repCount: _repCount,
            feedback: feedback,
            feedbackType: feedbackType,
            poses: detectedPoses,
            imageWidth: image.width,
            imageHeight: image.height,
            hasFirstFrame: true,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[PushUpCubit] _processFrame error: $e');
      AnalyticsService.trackError('PushUpCubit._processFrame', e, st);
    }
  }

  // Resets the rep state machine when the pose is lost or out of position,
  // so a partial rep can't carry across an interruption.
  void _resetRep() {
    _started = false;
    _down = false;
    _reachedDepth = false;
    _smoothAngle = null;
  }

  double _angleDeg(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final v1x = ax - bx, v1y = ay - by;
    final v2x = cx - bx, v2y = cy - by;
    final dot = v1x * v2x + v1y * v2y;
    final mag =
        math.sqrt(v1x * v1x + v1y * v1y) * math.sqrt(v2x * v2x + v2y * v2y);
    if (mag == 0) return 0;
    return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  /// Returns (leftAngle, rightAngle), or null if either side is not visible.
  (double, double)? _bothElbowAngles(DetectedPose pose) {
    double? sideAngle(
      PoseLandmarkType shoulder,
      PoseLandmarkType elbow,
      PoseLandmarkType wrist,
    ) {
      final s = pose.getLandmark(shoulder);
      final e = pose.getLandmark(elbow);
      final w = pose.getLandmark(wrist);
      if (s == null || e == null || w == null) return null;
      if (s.likelihood < 0.65 || e.likelihood < 0.65 || w.likelihood < 0.65) {
        return null;
      }
      return _angleDeg(s.x, s.y, e.x, e.y, w.x, w.y);
    }

    final left = sideAngle(
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final right = sideAngle(
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    if (left == null || right == null) return null;
    return (left, right);
  }

  bool _isWristsBelowElbows(DetectedPose pose) {
    bool left = false, right = false;

    final lw = pose.getLandmark(PoseLandmarkType.leftWrist);
    final le = pose.getLandmark(PoseLandmarkType.leftElbow);
    if (lw != null &&
        le != null &&
        lw.likelihood >= 0.6 &&
        le.likelihood >= 0.6) {
      left = lw.y > le.y;
    }

    final rw = pose.getLandmark(PoseLandmarkType.rightWrist);
    final re = pose.getLandmark(PoseLandmarkType.rightElbow);
    if (rw != null &&
        re != null &&
        rw.likelihood >= 0.6 &&
        re.likelihood >= 0.6) {
      right = rw.y > re.y;
    }

    return left && right;
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
