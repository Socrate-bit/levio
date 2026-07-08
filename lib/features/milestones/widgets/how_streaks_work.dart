import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// Explains how streaks and freezes work. Dismissible only when [onDismiss] is
/// provided; otherwise the card is shown permanently (e.g. on the Streak screen).
class HowStreaksWork extends StatelessWidget {
  final VoidCallback? onDismiss;

  const HowStreaksWork({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18.sp, color: c.textSecondary),
              SizedBox(width: 8.w),
              Text(
                l10n.milestonesHowStreaksWork,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              if (onDismiss != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: withHaptic(onDismiss!),
                  child: Icon(Icons.close, size: 18.sp, color: c.textSecondary),
                ),
              ],
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            l10n.milestonesStreakExplanation,
            style: TextStyle(
              fontSize: 13.sp,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
