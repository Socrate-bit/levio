import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Spacer(flex: 1,),
          Text(
            l10n.onboardingPaywallTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // App screenshot
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/exemple.png',
              height: 320,
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
                  Icon(Icons.check, size: 20, color: c.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.onboardingPaywallNoPayment,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Try for free button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: withHaptic(onContinue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    l10n.onboardingPaywallTryFree,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.card,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingPaywallNoCommitment,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
              ),
              const SizedBox(height: 12),
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
                        fontSize: 12,
                        color: c.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '  \u2022  ',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                  Text(
                    l10n.onboardingPaywallRestore,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    '  \u2022  ',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
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
                        fontSize: 12,
                        color: c.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    '  \u2022  ',
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
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
                        fontSize: 12,
                        color: c.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
