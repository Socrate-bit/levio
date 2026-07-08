import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/widgets/routine_picker_screen.dart';

/// Lets the user review their routine during onboarding: the chosen steps are
/// shown as locked, read-only cards (reordering / editing happens only in the
/// full [RoutinePickerScreen]) above a button that opens that picker. The
/// chosen labels become the alarm's `routine` mission.
class RelaxingActivitiesStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  // Which preset catalog the picker offers (v2 passes wake/night). Null keeps
  // the legacy catalog for the v1 funnel.
  final RoutineMode? mode;
  // Leading icon on the modify button (bedtime by default, sun for wake).
  final IconData leadingIcon;

  const RelaxingActivitiesStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
    this.mode,
    this.leadingIcon = Icons.bedtime_outlined,
  });

  @override
  State<RelaxingActivitiesStep> createState() => _RelaxingActivitiesStepState();
}

class _RelaxingActivitiesStepState extends State<RelaxingActivitiesStep> {
  // How many catalog steps to pre-select the first time the step is shown.
  static const _kDefaultStepCount = 3;

  @override
  void initState() {
    super.initState();
    // Seed a ready-made routine the first time the step is shown so the user
    // starts from preselected steps they can modify.
    if (widget.selected.isEmpty) {
      final defaults = _defaultSteps();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(defaults);
      });
    }
  }

  /// First few steps of the active catalog, used as the initial routine.
  List<String> _defaultSteps() {
    switch (widget.mode) {
      case RoutineMode.wake:
        return routineWakePresetSteps.take(_kDefaultStepCount).toList();
      case RoutineMode.night:
        return routineNightPresetSteps.take(_kDefaultStepCount).toList();
      case null:
        return routinePresetSteps.take(_kDefaultStepCount).toList();
    }
  }

  // Opens the full chip selector to add/remove/reorder steps.
  Future<void> _openPicker() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoutinePickerScreen(preselected: widget.selected, mode: widget.mode),
      ),
    );
    if (result != null) widget.onChanged(result);
  }

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
            widget.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.subtitle,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 24.h),
          // Locked, read-only preview of the chosen steps.
          for (var i = 0; i < widget.selected.length; i++) ...[
            _LockedStepCard(
              index: i + 1,
              label: localizedItemName(l10n, widget.selected[i]),
            ),
            SizedBox(height: 10.h),
          ],
          SizedBox(height: 6.h),
          // Button to open the chip selector and modify the routine.
          GestureDetector(
            onTap: withHaptic(_openPicker),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: c.separator),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.leadingIcon, size: 20.sp, color: c.textPrimary),
                  SizedBox(width: 10.w),
                  Text(
                    l10n.onboardingRoutineModify,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A chosen routine step shown as a static, numbered card. Locked: no drag or
/// delete — those live in the full picker.
class _LockedStepCard extends StatelessWidget {
  final int index;
  final String label;

  const _LockedStepCard({required this.index, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.separator, width: 1.5),
      ),
      child: Row(
        children: [
          // Order badge.
          Container(
            width: 26.w,
            height: 26.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: c.background,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
