import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../settings/screens/privacy_policy_screen.dart';
import '../../settings/screens/terms_conditions_screen.dart';

class PaywallStep extends StatelessWidget {
  final VoidCallback onContinue;

  const PaywallStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Spacer(flex: 1,),
          Text(
            l10n.onboardingPaywallTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 24.h),
          // App screenshot
          ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Image.asset(
              'assets/exemple.png',
              height: 320.h,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(flex: 1),
          // No Payment Due Now
          Column(

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20.sp, color: c.textPrimary),
                  SizedBox(width: 6.w),
                  Text(
                    l10n.onboardingPaywallNoPayment,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Try for free button
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
                    l10n.onboardingPaywallTryFree,
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
                l10n.onboardingPaywallNoCommitment,
                style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
              ),
              SizedBox(height: 12.h),
              // Links
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                    child: Text(
                      l10n.onboardingPaywallPrivacy,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: c.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '  \u2022  ',
                    style: TextStyle(fontSize: 12.sp, color: c.textSecondary),
                  ),
                  Text(
                    l10n.onboardingPaywallRestore,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: c.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    '  \u2022  ',
                    style: TextStyle(fontSize: 12.sp, color: c.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    ),
                    child: Text(
                      l10n.onboardingPaywallTerms,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: c.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '  \u2022  ',
                    style: TextStyle(fontSize: 12.sp, color: c.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      l10n.onboardingPaywallEula,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: c.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
