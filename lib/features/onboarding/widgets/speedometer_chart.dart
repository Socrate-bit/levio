import 'dart:math';
import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/shared/theme/app_theme.dart';

class SpeedometerChart extends StatelessWidget {
  const SpeedometerChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
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
              painter: _SpeedometerPainter(
                multiplierLabel: l10n.onboardingSpeedometerMultiplier,
                fasterLabel: l10n.onboardingSpeedometerFaster,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    l10n.onboardingSpeedometerSlow,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    l10n.onboardingSpeedometerGroggy,
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
                    l10n.onboardingSpeedometerInstant,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    l10n.onboardingSpeedometerActive,
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
            l10n.onboardingSpeedometerBody,
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
  final String multiplierLabel;
  final String fasterLabel;

  _SpeedometerPainter({
    required this.multiplierLabel,
    required this.fasterLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final radius = size.width / 2 - 20;

    // Gauge arc (red → yellow → green) drawn as small segments
    const startAngle = pi;
    const sweepAngle = pi;
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const segmentCount = 60;
    const segSweep = sweepAngle / segmentCount;
    final gradientColors = [
      AppColors.error,
      const Color(0xFFFF9800),
      const Color(0xFFFFC107),
      const Color(0xFF8BC34A),
      AppColors.success,
    ];
    const gradientStops = [0.0, 0.25, 0.5, 0.75, 1.0];

    for (var i = 0; i < segmentCount; i++) {
      final t = i / (segmentCount - 1);
      final color = _lerpGradient(gradientColors, gradientStops, t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.butt
        ..color = color;
      canvas.drawArc(
          arcRect, startAngle + i * segSweep, segSweep + 0.01, false, paint);
    }

    // Round caps at both ends
    final capPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    capPaint.color = gradientColors.first;
    canvas.drawArc(arcRect, startAngle, 0.01, false, capPaint);
    capPaint.color = gradientColors.last;
    canvas.drawArc(arcRect, startAngle + sweepAngle - 0.01, 0.01, false, capPaint);

    // Tick marks
    const tickCount = 20;
    for (var i = 0; i <= tickCount; i++) {
      final angle = pi + (pi * i / tickCount);
      final outerR = radius + 11;
      final innerR = radius + 5;
      final outer = Offset(cx + outerR * cos(angle), cy + outerR * sin(angle));
      final inner = Offset(cx + innerR * cos(angle), cy + innerR * sin(angle));
      canvas.drawLine(
        outer,
        inner,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
    }

    // Needle pointing to max (instant)
    const needleAngle = pi + pi * 0.95;
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
      text: TextSpan(
        text: multiplierLabel,
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
      Offset(cx - textPainter.width / 2, cy - 70),
    );

    // "FASTER" text
    final fasterPainter = TextPainter(
      text: TextSpan(
        text: fasterLabel,
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
      Offset(cx - fasterPainter.width / 2, cy - 30),
    );
  }

  /// Linearly interpolate a color from a gradient defined by colors + stops
  static Color _lerpGradient(
      List<Color> colors, List<double> stops, double t) {
    for (var i = 0; i < stops.length - 1; i++) {
      if (t <= stops[i + 1]) {
        final localT = (t - stops[i]) / (stops[i + 1] - stops[i]);
        return Color.lerp(colors[i], colors[i + 1], localT)!;
      }
    }
    return colors.last;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
