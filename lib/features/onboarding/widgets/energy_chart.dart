import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class EnergyChart extends StatelessWidget {
  const EnergyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingEnergyTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _EnergyChartPainter(
                textColor: c.textSecondary,
                levioLabel: l10n.onboardingEnergyLevio,
                snoozeLabel: l10n.onboardingEnergySnoozeCycle,
                groggyLabel: l10n.onboardingEnergyGroggyZone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyChartPainter extends CustomPainter {
  final Color textColor;
  final String levioLabel;
  final String snoozeLabel;
  final String groggyLabel;

  _EnergyChartPainter({
    required this.textColor,
    required this.levioLabel,
    required this.snoozeLabel,
    required this.groggyLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Snooze cycle — red zigzag line that stays low
    final snoozePaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final snoozePath = Path();
    snoozePath.moveTo(0, h * 0.75);
    snoozePath.cubicTo(
      w * 0.05,
      h * 0.55,
      w * 0.10,
      h * 0.55,
      w * 0.15,
      h * 0.70,
    );
    snoozePath.cubicTo(
      w * 0.20,
      h * 0.85,
      w * 0.22,
      h * 0.90,
      w * 0.28,
      h * 0.65,
    );
    snoozePath.cubicTo(
      w * 0.34,
      h * 0.40,
      w * 0.38,
      h * 0.45,
      w * 0.42,
      h * 0.70,
    );
    snoozePath.cubicTo(
      w * 0.46,
      h * 0.90,
      w * 0.48,
      h * 0.92,
      w * 0.55,
      h * 0.65,
    );
    snoozePath.cubicTo(
      w * 0.62,
      h * 0.38,
      w * 0.65,
      h * 0.45,
      w * 0.70,
      h * 0.70,
    );
    // Flatten into groggy zone
    snoozePath.cubicTo(w * 0.78, h * 0.78, w * 0.88, h * 0.73, w, h * 0.70);

    canvas.drawPath(snoozePath, snoozePaint);

    // Levio protocol — thick black line that rises sharply
    final levioPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final levioPath = Path();
    levioPath.moveTo(0, h * 0.75);
    levioPath.cubicTo(
      w * 0.15,
      h * 0.70,
      w * 0.30,
      h * 0.55,
      w * 0.45,
      h * 0.30,
    );
    levioPath.cubicTo(w * 0.60, h * 0.05, w * 0.80, h * 0.02, w, h * 0.02);

    canvas.drawPath(levioPath, levioPaint);

    // Levio endpoint dot
    canvas.drawCircle(Offset(w, h * 0.02), 5, Paint()..color = Colors.black);

    // Snooze endpoint circle (hollow)
    canvas.drawCircle(
      Offset(w, h * 0.70),
      4,
      Paint()
        ..color = const Color(0xFFFF6B6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    final labelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);

    // "Levio Protocol" pill label
    _drawPill(canvas, Offset(w * 0.05, h * 0.15), levioLabel, Colors.black);

    // "Snooze Cycle" label
    _drawText(
      canvas,
      snoozeLabel,
      Offset(w * 0.08, h * 0.98),
      labelStyle.copyWith(color: const Color(0xFFFF6B6B)),
    );

    // "GROGGY ZONE" label
    _drawText(
      canvas,
      groggyLabel,
      Offset(w * 0.68, h * 0.98),
      labelStyle.copyWith(color: const Color(0xFFFF6B6B)),
    );
  }

  void _drawPill(Canvas canvas, Offset pos, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(text: '\u26A1 ', style: TextStyle(fontSize: 10)),
          TextSpan(
            text: text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pos.dx,
        pos.dy - textPainter.height / 2 - 6,
        textPainter.width + 16,
        textPainter.height + 12,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    textPainter.paint(
      canvas,
      Offset(pos.dx + 8, pos.dy - textPainter.height / 2),
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
