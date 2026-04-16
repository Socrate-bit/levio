import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// Thin wrapper — keeps state serialisable and Equatable-friendly.
class DetectedLandmark {
  final PoseLandmarkType type;
  final double x, y, likelihood;
  const DetectedLandmark(this.type, this.x, this.y, this.likelihood);
}

class DetectedPose {
  final List<DetectedLandmark> landmarks;
  const DetectedPose(this.landmarks);

  DetectedLandmark? getLandmark(PoseLandmarkType type) {
    for (final l in landmarks) {
      if (l.type == type) return l;
    }
    return null;
  }

  bool get hasLandmarks => landmarks.isNotEmpty;
}

enum FeedbackType { warning, positive }

/// Localisation-safe feedback keys emitted by exercise cubits.
enum FeedbackKey {
  moveIntoFrame,
  keepGoing,
  pushupPosition,
  startPushups,
  pushupGoDeeper,
  squatPosition,
  startSquats,
  squatGoDeeper,
}

// ---------- States ----------

abstract class PushUpState extends Equatable {
  const PushUpState();

  @override
  List<Object?> get props => [];
}

class PushUpInitial extends PushUpState {
  const PushUpInitial();
}

class CameraLoading extends PushUpState {
  const CameraLoading();
}

class SessionActive extends PushUpState {
  final CameraController camera;
  final int repCount;
  final FeedbackKey? feedback;
  final FeedbackType feedbackType;
  final List<DetectedPose> poses;
  final int imageWidth;
  final int imageHeight;
  final bool hasFirstFrame;

  const SessionActive({
    required this.camera,
    required this.repCount,
    this.feedback,
    this.feedbackType = FeedbackType.warning,
    required this.poses,
    required this.imageWidth,
    required this.imageHeight,
    this.hasFirstFrame = false,
  });

  SessionActive copyWith({
    int? repCount,
    FeedbackKey? feedback,
    bool clearFeedback = false,
    FeedbackType? feedbackType,
    List<DetectedPose>? poses,
    int? imageWidth,
    int? imageHeight,
    bool? hasFirstFrame,
  }) {
    return SessionActive(
      camera: camera,
      repCount: repCount ?? this.repCount,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      feedbackType: feedbackType ?? this.feedbackType,
      poses: poses ?? this.poses,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      hasFirstFrame: hasFirstFrame ?? this.hasFirstFrame,
    );
  }

  @override
  List<Object?> get props =>
      [repCount, feedback, feedbackType, poses, imageWidth, imageHeight, hasFirstFrame];
}

class SessionComplete extends PushUpState {
  final int repCount;
  const SessionComplete({required this.repCount});

  @override
  List<Object?> get props => [repCount];
}

class SessionGoalReached extends PushUpState {
  final int repCount;
  const SessionGoalReached({required this.repCount});

  @override
  List<Object?> get props => [repCount];
}
