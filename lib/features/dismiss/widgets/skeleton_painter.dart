import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../cubit/pushup_state.dart';

// Major joints to draw as dots
const _joints = [
  PoseLandmarkType.leftShoulder,
  PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftElbow,
  PoseLandmarkType.rightElbow,
  PoseLandmarkType.leftWrist,
  PoseLandmarkType.rightWrist,
  PoseLandmarkType.leftHip,
  PoseLandmarkType.rightHip,
  PoseLandmarkType.leftKnee,
  PoseLandmarkType.rightKnee,
  PoseLandmarkType.leftAnkle,
  PoseLandmarkType.rightAnkle,
];

// Body connections to draw (push-up focused: arms, torso, legs)
const _connections = [
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
];

class SkeletonPainter extends CustomPainter {
  final List<DetectedPose> poses;
  final int imageWidth;
  final int imageHeight;

  SkeletonPainter({
    required this.poses,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty || imageWidth == 0 || imageHeight == 0) return;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    final linePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.9)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      if (!pose.hasLandmarks) continue;

      for (final conn in _connections) {
        final a = pose.getLandmark(conn[0]);
        final b = pose.getLandmark(conn[1]);
        if (a == null ||
            b == null ||
            a.likelihood < 0.65 ||
            b.likelihood < 0.65) {
          continue;
        }
        canvas.drawLine(
          Offset(a.x * scaleX, a.y * scaleY),
          Offset(b.x * scaleX, b.y * scaleY),
          linePaint,
        );
      }

      for (final type in _joints) {
        final lm = pose.getLandmark(type);
        if (lm == null || lm.likelihood < 0.65) continue;
        canvas.drawCircle(
          Offset(lm.x * scaleX, lm.y * scaleY),
          6,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter old) =>
      poses != old.poses ||
      imageWidth != old.imageWidth ||
      imageHeight != old.imageHeight;
}
