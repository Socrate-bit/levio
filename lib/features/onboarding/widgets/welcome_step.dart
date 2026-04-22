import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onBuildPlan;
  final VoidCallback onSignIn;

  const WelcomeStep({
    super.key,
    required this.onBuildPlan,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            Text(
              l10n.onboardingWelcomeTitle,
              style: TextStyle(
                fontSize: 34.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.onboardingWelcomeSubtitle,
              style: TextStyle(fontSize: 17.sp, color: c.textSecondary),
            ),
            SizedBox(height: 32.h),
            // Stars placeholder
            Container(
              height: 60.h,
              alignment: Alignment.centerLeft,
              child: Text(
                '⭐⭐⭐⭐⭐',
                style: TextStyle(fontSize: 28.sp),
              ),
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: withHaptic(onBuildPlan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.onboardingBuildPlan,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: c.card,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward, size: 20.sp, color: c.card),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: Text(
                l10n.onboardingJoin500k,
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: GestureDetector(
                onTap: withHaptic(onSignIn),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                    children: [
                      TextSpan(text: l10n.onboardingAlreadyAccount),
                      TextSpan(
                        text: l10n.onboardingSignIn,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
