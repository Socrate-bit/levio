import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

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
        children: [
          const Spacer(flex: 1),
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
          // Phone mockup placeholder
          Container(
            height: 320,
            width: 180,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.separator, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  // Status bar
                  Container(
                    height: 28,
                    color: c.separator,
                    child: Center(
                      child: Text(
                        '8:00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Progress dots
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(AppColors.orange, true),
                        const SizedBox(width: 4),
                        _dot(AppColors.orange, true),
                        const SizedBox(width: 4),
                        _dot(c.separator, false),
                      ],
                    ),
                  ),
                  // Counter
                  Expanded(
                    child: Container(
                      color: c.separator,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '2',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                            Text(
                              l10n.onboardingPaywallSecondsRemaining,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom bar
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    color: c.card,
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.circle,
                              size: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.onboardingPaywallKeepGoing,
                            style: TextStyle(
                              fontSize: 8,
                              color: c.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
          // No Payment Due Now
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
              onPressed: onContinue,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.onboardingPaywallPrivacy,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text('  \u2022  ',
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
              Text(
                l10n.onboardingPaywallRestore,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text('  \u2022  ',
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
              Text(
                l10n.onboardingPaywallTerms,
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _dot(Color color, bool filled) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1),
      ),
    );
  }
}
