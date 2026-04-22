import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class TrialReminderStep extends StatelessWidget {
  final VoidCallback onContinue;

  const TrialReminderStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            l10n.onboardingTrialTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 40.h),
          // Bell with notification badge
          SizedBox(
            width: 100.w,
            height: 100.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 80.sp,
                    color: c.textSecondary,
                  ),
                ),
                Positioned(
                  top: -4.h,
                  right: 4.w,
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          // No Payment Due Now
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 20.sp, color: AppColors.orange),
              SizedBox(width: 6.w),
              Text(
                l10n.onboardingTrialNoPayment,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Continue for free button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: withHaptic(onContinue),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                l10n.onboardingTrialContinueFree,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: c.card,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.onboardingTrialPrice,
            style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
