import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../milestones/services/streak_service.dart';
import '../cubit/insights_state.dart';

/// GitHub-style contribution grid: one column per week, one rounded cell per
/// day. Colours match the home week view — win (blue), freeze (light blue),
/// loss (red), no alarm (faint).
class StreakHeatmap extends StatelessWidget {
  final List<HeatmapDay> days;

  const StreakHeatmap({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final weeks = (days.length / 7).ceil();

    final winColor = AppColors.orange;
    final freezeColor = AppColors.blue.withAlpha(90);
    final lossColor = AppColors.error;
    final emptyColor = c.textSecondary.withAlpha(20);

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
                    winColor: winColor,
                    freezeColor: freezeColor,
                    lossColor: lossColor,
                    emptyColor: emptyColor,
                    todayBorder: c.textPrimary.withAlpha(120),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _LegendItem(color: winColor, label: l10n.insightsWin),
              SizedBox(width: 14.w),
              _LegendItem(color: freezeColor, label: l10n.insightsFreeze),
              SizedBox(width: 14.w),
              _LegendItem(color: lossColor, label: l10n.insightsLoss),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<HeatmapDay> days;
  final double cell;
  final double gap;
  final Color winColor;
  final Color freezeColor;
  final Color lossColor;
  final Color emptyColor;
  final Color todayBorder;

  _HeatmapPainter({
    required this.days,
    required this.cell,
    required this.gap,
    required this.winColor,
    required this.freezeColor,
    required this.lossColor,
    required this.emptyColor,
    required this.todayBorder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cell * 0.28);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

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
        color = emptyColor.withAlpha(10);
      } else {
        switch (day.status) {
          case DayStatus.done:
            color = winColor;
          case DayStatus.frozen:
            color = freezeColor;
          case DayStatus.missed:
            color = lossColor;
          case DayStatus.none:
            color = emptyColor;
        }
      }

      canvas.drawRRect(rect, Paint()..color = color);

      if (day.date == todayDate) {
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

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) =>
      oldDelegate.days != days || oldDelegate.cell != cell;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11.w,
          height: 11.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: c.textSecondary),
        ),
      ],
    );
  }
}
