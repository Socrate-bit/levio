import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../cubit/insights_state.dart';

/// Line/area chart of success rate (0–100%) over time. Bucketing (daily /
/// weekly / monthly) is decided by the cubit; this widget only renders the
/// [ProgressPoint]s and formats axis labels for the given [range].
class SuccessProgressionChart extends StatelessWidget {
  final List<ProgressPoint> points;
  final InsightsRange range;

  const SuccessProgressionChart({
    super.key,
    required this.points,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final hasData = points.where((p) => p.rate != null).length >= 2;
    final labels = [for (final p in points) _label(l10n, p.date)];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsProgressionTitle,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 150.h,
            child: hasData
                ? CustomPaint(
                    size: Size.infinite,
                    painter: _ProgressionPainter(
                      points: points,
                      labels: labels,
                      lineColor: AppColors.orange,
                      gridColor: c.separator,
                      textColor: c.textSecondary,
                    ),
                  )
                : Center(
                    child: Text(
                      l10n.insightsNoData,
                      style:
                          TextStyle(fontSize: 13.sp, color: c.textSecondary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, DateTime date) {
    switch (range) {
      case InsightsRange.week:
        return localizedDayShort(l10n, date.weekday % 7);
      case InsightsRange.month:
        return '${date.day}';
      case InsightsRange.allTime:
        return localizedMonth(l10n, date.month);
    }
  }
}

class _ProgressionPainter extends CustomPainter {
  final List<ProgressPoint> points;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _ProgressionPainter({
    required this.points,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelGutter = 22.0;
    final chartH = size.height - labelGutter;
    final w = size.width;

    // Horizontal gridlines at 0 / 50 / 100%.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final frac in const [0.0, 0.5, 1.0]) {
      final y = chartH * frac;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    if (points.isEmpty) return;

    double xFor(int i) =>
        points.length == 1 ? w / 2 : w * i / (points.length - 1);
    double yFor(double rate) => chartH * (1 - rate / 100);

    // Build the line through non-null points.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final fill = Path();
    var started = false;
    final drawn = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final rate = points[i].rate;
      if (rate == null) continue;
      final p = Offset(xFor(i), yFor(rate));
      drawn.add(p);
      if (!started) {
        path.moveTo(p.dx, p.dy);
        fill.moveTo(p.dx, chartH);
        fill.lineTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
        fill.lineTo(p.dx, p.dy);
      }
    }

    if (drawn.isNotEmpty) {
      fill.lineTo(drawn.last.dx, chartH);
      fill.close();
      canvas.drawPath(fill, Paint()..color = lineColor.withAlpha(30));
      canvas.drawPath(path, linePaint);
      for (final p in drawn) {
        canvas.drawCircle(p, 3, Paint()..color = lineColor);
      }
    }

    // X-axis labels (skip some when crowded).
    final step = points.length > 8 ? 2 : 1;
    final labelStyle = TextStyle(fontSize: 10.sp, color: textColor);
    for (var i = 0; i < points.length; i += step) {
      if (i >= labels.length) break;
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (xFor(i) - tp.width / 2).clamp(0.0, w - tp.width);
      tp.paint(canvas, Offset(x, chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressionPainter oldDelegate) =>
      oldDelegate.points != points;
}
