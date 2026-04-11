import 'dart:math';
import 'package:flutter/material.dart';

class DnaHelix extends StatelessWidget {
  const DnaHelix({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 140,
      child: CustomPaint(
        painter: _DnaHelixPainter(),
      ),
    );
  }
}

class _DnaHelixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;
    const amplitude = 28.0;
    const rungs = 8;
    final rungSpacing = h / (rungs + 1);

    // Draw connecting rungs first (behind strands)
    for (var i = 1; i <= rungs; i++) {
      final y = i * rungSpacing;
      final t = (i / rungs) * 2 * pi;
      final x1 = cx + amplitude * sin(t);
      final x2 = cx - amplitude * sin(t);

      // Only draw rungs where strands are close to crossing
      final separation = (x1 - x2).abs();
      if (separation < amplitude * 1.8) {
        final rungPaint = Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

        // Gradient each rung
        rungPaint.shader = LinearGradient(
          colors: [
            _colorAt(i / rungs, true),
            _colorAt(i / rungs, false),
          ],
        ).createShader(Rect.fromPoints(Offset(x1, y), Offset(x2, y)));

        canvas.drawLine(Offset(x1, y), Offset(x2, y), rungPaint);
      }
    }

    // Draw the two helix strands
    _drawStrand(canvas, size, cx, amplitude, true);
    _drawStrand(canvas, size, cx, amplitude, false);
  }

  void _drawStrand(Canvas canvas, Size size, double cx, double amplitude, bool isFirst) {
    final path = Path();
    final steps = 100;

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = t * size.height;
      final angle = t * 2 * pi * 1.5;
      final x = cx + amplitude * sin(angle + (isFirst ? 0 : pi));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Gradient along the strand
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isFirst
          ? [const Color(0xFF9C27B0), const Color(0xFF00BCD4)]
          : [const Color(0xFF00BCD4), const Color(0xFFE91E63)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  Color _colorAt(double t, bool isFirst) {
    if (isFirst) {
      return Color.lerp(const Color(0xFF9C27B0), const Color(0xFF00BCD4), t)!;
    }
    return Color.lerp(const Color(0xFF00BCD4), const Color(0xFFE91E63), t)!;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
