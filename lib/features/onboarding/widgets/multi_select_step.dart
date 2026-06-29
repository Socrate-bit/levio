import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// A single selectable row: a leading emoji and a localized label. [value] is
/// the stable key stored in state (independent of the displayed translation).
class MultiSelectOption {
  final String value;
  final String emoji;
  final String label;

  const MultiSelectOption({
    required this.value,
    required this.emoji,
    required this.label,
  });
}

/// Multi-select question screen with an emoji per option. Mirrors [SurveyStep]
/// visually but lets the user pick several answers; the parent enables Continue
/// once at least one is selected.
class MultiSelectStep extends StatelessWidget {
  final String question;
  final String? subtitle;
  final List<MultiSelectOption> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const MultiSelectStep({
    super.key,
    required this.question,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            question,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle ?? '',
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 24.h),
          ...options.map((opt) {
            final isSelected = selected.contains(opt.value);
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: GestureDetector(
                onTap: withHaptic(() => onToggle(opt.value)),
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected ? c.textPrimary : c.separator,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(opt.emoji, style: TextStyle(fontSize: 22.sp)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7.r),
                          color: isSelected
                              ? c.textPrimary
                              : Colors.transparent,
                          border: Border.all(
                            color:
                                isSelected ? c.textPrimary : c.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 16.sp, color: c.card)
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
