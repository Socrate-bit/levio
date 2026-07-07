import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../cubit/insights_state.dart';

/// GitHub-style contribution grid: one column per week, one rounded cell per
/// day. Cell colour reflects completed wake-ups (orange, brighter with more)
/// versus missed-only days (faint red).
class StreakHeatmap extends StatelessWidget {
  final List<HeatmapDay> days;

  const StreakHeatmap({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final weeks = (days.length / 7).ceil();
    final today = DateTime.now();
    final todayKey = _key(DateTime(today.year, today.month, today.day));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsHeatmapTitle,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 3.0;
              final cell = (constraints.maxWidth - (weeks - 1) * gap) / weeks;
              final height = cell * 7 + gap * 6;
              return SizedBox(
                width: constraints.maxWidth,
                height: height,
                child: CustomPaint(
                  painter: _HeatmapPainter(
                    days: days,
                    cell: cell,
                    gap: gap,
                    todayKey: todayKey,
                    emptyColor: c.textSecondary.withAlpha(20),
                    missedColor: AppColors.error.withAlpha(60),
                    completedColor: AppColors.orange,
                    todayBorder: c.textPrimary.withAlpha(120),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 10.h),
          _Legend(c: c),
        ],
      ),
    );
  }

  String _key(DateTime t) => '${t.year}-${t.month}-${t.day}';
}

class _HeatmapPainter extends CustomPainter {
  final List<HeatmapDay> days;
  final double cell;
  final double gap;
  final String todayKey;
  final Color emptyColor;
  final Color missedColor;
  final Color completedColor;
  final Color todayBorder;

  _HeatmapPainter({
    required this.days,
    required this.cell,
    required this.gap,
    required this.todayKey,
    required this.emptyColor,
    required this.missedColor,
    required this.completedColor,
    required this.todayBorder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cell * 0.28);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final col = i ~/ 7;
      final row = i % 7;
      final x = col * (cell + gap);
      final y = row * (cell + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cell, cell),
        radius,
      );

      final Color color;
      if (day.date.isAfter(todayDate)) {
        // Future days: keep the grid rectangular but barely visible.
        color = emptyColor.withAlpha(10);
      } else if (day.count > 0) {
        color = completedColor.withAlpha(_intensityAlpha(day.count));
      } else if (day.missed) {
        color = missedColor;
      } else {
        color = emptyColor;
      }

      canvas.drawRRect(rect, Paint()..color = color);

      if ('${day.date.year}-${day.date.month}-${day.date.day}' == todayKey) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = todayBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  int _intensityAlpha(int count) {
    if (count >= 3) return 255;
    if (count == 2) return 190;
    return 120;
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.days != days || oldDelegate.cell != cell;
}

class _Legend extends StatelessWidget {
  final AppColors c;
  const _Legend({required this.c});

  @override
  Widget build(BuildContext context) {
    Widget swatch(Color color) => Container(
          width: 12.w,
          height: 12.w,
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        swatch(c.textSecondary.withAlpha(20)),
        swatch(AppColors.orange.withAlpha(120)),
        swatch(AppColors.orange.withAlpha(190)),
        swatch(AppColors.orange),
      ],
    );
  }
}
