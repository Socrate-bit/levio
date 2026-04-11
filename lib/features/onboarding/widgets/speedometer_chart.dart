import 'dart:math';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class SpeedometerChart extends StatelessWidget {
  const SpeedometerChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.separator),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 260,
            height: 150,
            child: CustomPaint(
              painter: _SpeedometerPainter(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    'Slow',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF5252),
                    ),
                  ),
                  Text(
                    'Groggy',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Instant',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Levio eliminates snooze friction for\ninstant wake ups.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = size.width / 2 - 20;

    // Gauge arc (red → yellow → green)
    const startAngle = pi;
    const sweepAngle = pi;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final gaugePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    gaugePaint.shader = SweepGradient(
      center: Alignment.center,
      startAngle: pi,
      endAngle: 2 * pi,
      colors: const [
        Color(0xFFFF5252),
        Color(0xFFFF9800),
        Color(0xFFFFC107),
        Color(0xFF8BC34A),
        Color(0xFF4CAF50),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(arcRect);

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, gaugePaint);

    // Needle pointing to ~80% (5x position)
    const needleAngle = pi + pi * 0.82;
    final needleLength = radius - 30;
    final needleEnd = Offset(
      cx + needleLength * cos(needleAngle),
      cy + needleLength * sin(needleAngle),
    );

    // Needle line
    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Needle hub
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()..color = Colors.black,
    );

    // "5.0x" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '5.0x',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2 + 8, cy - 70),
    );

    // "FASTER" text
    final fasterPainter = TextPainter(
      text: TextSpan(
        text: 'FASTER',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: Colors.grey[600],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fasterPainter.paint(
      canvas,
      Offset(cx - fasterPainter.width / 2 + 8, cy - 30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
