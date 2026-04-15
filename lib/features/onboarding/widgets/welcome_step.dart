import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            Text(
              l10n.onboardingWelcomeTitle,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboardingWelcomeSubtitle,
              style: TextStyle(fontSize: 17, color: c.textSecondary),
            ),
            const SizedBox(height: 32),
            // Stars placeholder
            Container(
              height: 60,
              alignment: Alignment.centerLeft,
              child: Text(
                '🏅⭐⭐⭐⭐⭐🏅',
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onBuildPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.onboardingBuildPlan,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.card,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20, color: c.card),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.onboardingJoin500k,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: onSignIn,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
