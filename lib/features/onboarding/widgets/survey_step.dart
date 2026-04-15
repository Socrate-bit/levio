import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class SurveyStep extends StatelessWidget {
  final String question;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onSelected;
  final List<IconData>? icons;

  const SurveyStep({
    super.key,
    required this.question,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            question,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedOption == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: withHaptic(() => onSelected(option)),
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
                      if (icons != null && index < icons!.length) ...[
                        Icon(icons![index],
                            size: 22, color: c.textSecondary),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? c.textPrimary : Colors.transparent,
                          border: Border.all(
                            color:
                                isSelected ? c.textPrimary : c.textSecondary,
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
