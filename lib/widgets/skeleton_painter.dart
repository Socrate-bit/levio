import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';

import '../bloc/pushup_state.dart';

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

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;

    final linePaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      if (!pose.hasLandmarks) continue;

      // Draw connections
      for (final connection in poseLandmarkConnections) {
        final start = pose.getLandmark(connection[0]);
        final end = pose.getLandmark(connection[1]);
        if (start == null ||
            end == null ||
            start.visibility < 0.5 ||
            end.visibility < 0.5) {
          continue;
        }

        canvas.drawLine(
          Offset(start.x * scaleX, start.y * scaleY),
          Offset(end.x * scaleX, end.y * scaleY),
          linePaint,
        );
      }

      // Draw joints
      for (final landmark in pose.landmarks) {
        if (landmark.visibility < 0.5) continue;
        canvas.drawCircle(
          Offset(landmark.x * scaleX, landmark.y * scaleY),
          4,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) =>
      poses != oldDelegate.poses ||
      imageWidth != oldDelegate.imageWidth ||
      imageHeight != oldDelegate.imageHeight;
}
