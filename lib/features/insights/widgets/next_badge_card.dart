import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../milestones/models/badge_model.dart';
import 'hexagon_badge.dart';

/// Shows progress toward the next unearned streak badge. When every streak
/// badge is earned, it celebrates completion instead.
class NextBadgeCard extends StatelessWidget {
  final BadgeModel? nextBadge;
  final int currentStreak;
  final VoidCallback? onTap;

  const NextBadgeCard({
    super.key,
    required this.nextBadge,
    required this.currentStreak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final badge = nextBadge;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: badge == null
            ? _allEarned(context, c, l10n)
            : _progress(context, c, l10n, badge),
      ),
    );
  }

  Widget _progress(
    BuildContext context,
    AppColors c,
    AppLocalizations l10n,
    BadgeModel badge,
  ) {
    final required = badge.requiredDays ?? 1;
    final ratio = (currentStreak / required).clamp(0.0, 1.0);
    final daysLeft = (required - currentStreak).clamp(0, required);

    return Row(
      children: [
        HexagonBadge(
          label: badge.displayValue,
          earned: false,
          size: 60.w,
          earnedColor: AppColors.orange,
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.insightsNextBadge,
                style: TextStyle(fontSize: 12.sp, color: c.textSecondary),
              ),
              SizedBox(height: 2.h),
              Text(
                localizedBadgeName(l10n, badge.id),
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8.h,
                  backgroundColor: c.background,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.orange),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                l10n.insightsDaysToBadge(daysLeft),
                style: TextStyle(fontSize: 12.sp, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _allEarned(
    BuildContext context,
    AppColors c,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        HexagonBadge(
          label: '★',
          earned: true,
          size: 60.w,
          earnedColor: const Color(0xFFB8860B),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            l10n.insightsAllBadgesEarned,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
