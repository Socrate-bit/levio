import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// Inline multi-select of wind-down activities, shown during onboarding. The
/// chosen labels become the bedtime alarm's `routine` mission. Reuses the
/// shared [routinePresetSteps] + [localizedItemName] so the labels match the
/// rest of the app's routine pickers.
class RelaxingActivitiesStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  const RelaxingActivitiesStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 24.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (final label in routinePresetSteps)
                _Chip(
                  label: localizedItemName(l10n, label),
                  selected: selected.contains(label),
                  onTap: () => onToggle(label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rounded pill chip mirroring the routine picker's chip style.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : c.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.orange : c.separator,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : c.textPrimary,
          ),
        ),
      ),
    );
  }
}
