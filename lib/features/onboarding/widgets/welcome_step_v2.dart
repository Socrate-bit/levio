import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// Redesigned welcome screen for the v2 funnel: top-anchored headline, larger
/// type, a prominent start button, a language flag top-right, and no email
/// sign-in link (that lives on the dedicated sign-in screen).
class WelcomeStepV2 extends StatelessWidget {
  final VoidCallback onBuildPlan;
  final VoidCallback onSignIn;

  const WelcomeStepV2({
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
            SizedBox(height: 8.h),
            // Rating (the language selector lives in the onboarding header).
            Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 22.sp)),
            SizedBox(height: 28.h),
            // Headline anchored to the top.
            Text(
              l10n.onboardingWelcomeTitle,
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.12,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.onboardingWelcomeSubtitle,
              style: TextStyle(fontSize: 19.sp, color: c.textSecondary),
            ),
            const Spacer(),
            // Mascot.
            Center(
              child: Image.asset(
                'assets/animations/happy_sun.gif',
                height: 160.h,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 62.h,
              child: ElevatedButton(
                onPressed: withHaptic(onBuildPlan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(31.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.onboardingBuildPlan,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: c.card,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward, size: 22.sp, color: c.card),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: Text(
                l10n.onboardingJoin500k,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: GestureDetector(
                onTap: withHaptic(onSignIn),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
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
