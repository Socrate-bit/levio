import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../cubit/onboarding_state.dart';

class ReferralStep extends StatelessWidget {
  final String code;
  final ReferralStatus status;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onSubmit;

  const ReferralStep({
    super.key,
    required this.code,
    required this.status,
    required this.onCodeChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              l10n.onboardingReferralTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.onboardingReferralSubtitle,
              style: TextStyle(fontSize: 16, color: c.textSecondary),
            ),
            const Spacer(),
            SizedBox(
              width: constraints.maxWidth - 48,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: onCodeChanged,
                      decoration: InputDecoration(
                        hintText: l10n.onboardingReferralLabel,
                        hintStyle: TextStyle(color: c.textSecondary),
                        filled: true,
                        fillColor: c.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.separator),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.separator),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    width: 90,
                    child: ElevatedButton(
                      onPressed: code.trim().isEmpty ||
                              status == ReferralStatus.checking
                          ? null
                          : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.textSecondary,
                        foregroundColor: c.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: status == ReferralStatus.checking
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.card,
                              ),
                            )
                          : Text(
                              l10n.onboardingReferralSubmit,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.card,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (status == ReferralStatus.valid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.onboardingReferralApplied,
                    style: TextStyle(
                        fontSize: 14, color: Colors.green.shade700),
                  ),
                ],
              ),
            ],
            if (status == ReferralStatus.invalid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.onboardingReferralInvalid,
                    style:
                        TextStyle(fontSize: 14, color: Colors.red.shade700),
                  ),
                ],
              ),
            ],
            if (status == ReferralStatus.exhausted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.block, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.onboardingReferralLimit,
                    style:
                        TextStyle(fontSize: 14, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
