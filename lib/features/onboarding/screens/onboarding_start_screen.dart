import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../widgets/language_selector.dart';
import '../widgets/sign_in_step.dart';
import '../widgets/welcome_step_v2.dart';

/// Shared onboarding start screen shown to both A/B variants. Lives outside the
/// funnels so the user lands here while the A/B variant resolves in the
/// background; tapping "Build my plan" commits the direction (via [onStart])
/// and enters the chosen funnel. Reuses the v2 welcome design.
class OnboardingStartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const OnboardingStartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar: "App of the Year" badge left, language selector right.
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.onboardingAppOfTheYear.toUpperCase(),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: LanguageFlagButton(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WelcomeStepV2(
                onBuildPlan: onStart,
                onSignIn: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const _StartSignInScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone sign-in screen reachable from the start screen's "Sign in" link.
class _StartSignInScreen extends StatelessWidget {
  const _StartSignInScreen();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.of(context).pop()),
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_left,
                          size: 20.sp, color: c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SignInStep(
                title: l10n.onboardingSignInTitle,
                subtitle: l10n.onboardingSignInSubtitle,
                onSkip: () => Navigator.of(context).pop(),
                // After sign-in, pop. AuthWrapper reactively routes to
                // AppGateWrapper because isInProgress is still false.
                onSignInComplete: () => Navigator.of(context).pop(),
                showSkip: false,
                blockNewAccounts: true,
                showEmail: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
