import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class DayPickerStep extends StatelessWidget {
  final List<bool> repeatDays;
  final ValueChanged<int> onToggle;

  const DayPickerStep({
    super.key,
    required this.repeatDays,
    required this.onToggle,
  });

  // repeatDays index: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
  // Display order: Mon-Sun
  static const _displayOrder = [1, 2, 3, 4, 5, 6, 0];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.onboardingDayPickerTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingDayPickerSubtitle,
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const SizedBox(height: 32),
          ..._displayOrder.map((dayIndex) {
            final isSelected = repeatDays[dayIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: withHaptic(() => onToggle(dayIndex)),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? c.textPrimary : c.separator,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        localizedDayFull(l10n, dayIndex),
                        style: TextStyle(
                          fontSize: 16,
                          color: c.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? c.textPrimary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? c.textPrimary
                                : c.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 16, color: c.card)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
