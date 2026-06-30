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

class SquatCubit extends Cubit<PushUpState> {
  SquatCubit({this.targetReps}) : super(const PushUpInitial());

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

  // Counting — angle-based hysteresis on the knee joint. A rep = drop below
  // _downEnter (full depth) then rise back above _upEnter. The wide gap between
  // the two survives landmark jitter; _partial gates the "go deeper" hint.
  bool _started = false; // seen standing (up position) at least once
  bool _down = false; // currently in a descent (below _partial)
  bool _reachedDepth = false; // hit full depth during the current descent
  double? _smoothAngle; // EMA-smoothed knee angle
  int _repCount = 0;
  static const double _upEnter = 165.0; // standing (legs near straight)
  static const double _downEnter = 130.0; // full depth
  static const double _partial = 150.0; // started going down
  static const double _emaAlpha = 0.6; // weight of the newest sample

  Future<void> startSession() async {
    emit(const CameraLoading());
    try {
      _detector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
        ),
      );

      final cameras = await availableCameras();
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _sensorOrientation = cam.sensorOrientation;

      _camera = CameraController(
        cam,
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
      AnalyticsService.trackError('SquatCubit.startSession', e, st);
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

        // Check landmark
        if (kneeAngle == null) {
          feedback = FeedbackKey.moveIntoFrame;
          _resetRep();
          feedbackType = FeedbackType.warning;
          detectedPoses = const [];
        } else {
          // Check position
          final kneesAboveAnkles = _isKneesAboveAnkles(pose);
          if (!kneesAboveAnkles) {
            _resetRep();
            feedback = FeedbackKey.squatPosition;
            feedbackType = FeedbackType.warning;
          } else {
            // Smoothed knee angle drives the hysteresis counter.
            _smoothAngle = _smoothAngle == null
                ? kneeAngle
                : _emaAlpha * kneeAngle + (1 - _emaAlpha) * _smoothAngle!;
            final angle = _smoothAngle!;

            if (!_started && angle >= _upEnter) {
              _started = true;
              feedback = FeedbackKey.startSquats;
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
                    feedback = FeedbackKey.squatGoDeeper;
                    feedbackType = FeedbackType.warning;
                  }
                }
              }
            }
          }
        }
      }

      if (state is SessionActive) {
        emit(current.copyWith(
          repCount: _repCount,
          feedback: feedback,
          feedbackType: feedbackType,
          poses: detectedPoses,
          imageWidth: image.width,
          imageHeight: image.height,
          hasFirstFrame: true,
        ));
      }
    } catch (e, st) {
      debugPrint('[SquatCubit] _processFrame error: $e');
      AnalyticsService.trackError('SquatCubit._processFrame', e, st);
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

  bool _isKneesAboveAnkles(DetectedPose pose) {
    bool left = false, right = false;

    final lk = pose.getLandmark(PoseLandmarkType.leftKnee);
    final la = pose.getLandmark(PoseLandmarkType.leftAnkle);
    if (lk != null &&
        la != null &&
        lk.likelihood >= 0.6 &&
        la.likelihood >= 0.6) {
      left = la.y > lk.y;
    }

    final rk = pose.getLandmark(PoseLandmarkType.rightKnee);
    final ra = pose.getLandmark(PoseLandmarkType.rightAnkle);
    if (rk != null &&
        ra != null &&
        rk.likelihood >= 0.6 &&
        ra.likelihood >= 0.6) {
      right = ra.y > rk.y;
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
    _camera = null;
    _detector?.close();
    _detector = null;
    _processing = false;
    if (goalReached) {
      emit(SessionGoalReached(repCount: count));
    } else {
      emit(SessionComplete(repCount: count));
    }
    await _camera?.dispose();
  }

  @override
  Future<void> close() async {
    await _camera?.stopImageStream();
    await _camera?.dispose();
    _detector?.close();
    return super.close();
  }
}
