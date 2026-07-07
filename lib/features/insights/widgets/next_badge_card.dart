import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../milestones/models/badge_model.dart';
import 'hexagon_badge.dart';

/// Shows the user's current streak badge and progress toward the next one,
/// matching the "Current Badge" card design: hexagon, label, name, remaining
/// days, and a progress bar, with a chevron affordance to open Milestones.
class NextBadgeCard extends StatelessWidget {
  final BadgeModel? currentBadge;
  final BadgeModel? nextBadge;
  final int currentStreak;
  final VoidCallback? onTap;

  const NextBadgeCard({
    super.key,
    required this.currentBadge,
    required this.nextBadge,
    required this.currentStreak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    // Hexagon + name show the current badge if earned, otherwise the upcoming one.
    final earned = currentBadge != null;
    final badge = currentBadge ?? nextBadge;

    final double progress;
    final String subtitle;
    if (nextBadge != null) {
      final required = nextBadge!.requiredDays ?? 1;
      progress = (currentStreak / required).clamp(0.0, 1.0);
      final daysLeft = (required - currentStreak).clamp(0, required);
      subtitle = l10n.insightsMoreDaysToBadge(
          daysLeft, localizedBadgeName(l10n, nextBadge!.id));
    } else {
      progress = 1.0;
      subtitle = l10n.insightsAllBadgesEarned;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            HexagonBadge(
              label: badge?.displayValue ?? '?',
              earned: earned,
              size: 62.w,
              earnedColor: AppColors.orange,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (earned
                            ? l10n.insightsCurrentBadge
                            : l10n.insightsNextBadge)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    badge != null ? localizedBadgeName(l10n, badge.id) : '--',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                  ),
                  SizedBox(height: 10.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7.h,
                      backgroundColor: c.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.orange),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right, size: 22.sp, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
