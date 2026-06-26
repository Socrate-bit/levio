import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../../app.dart';
import '../../../shared/theme/app_theme.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../models/mission.dart';
import '../models/mission_config.dart';
import 'affirmation_picker_screen.dart';
import 'item_picker_screen.dart';
import 'random_pool_picker_screen.dart';

/// Shows a bottom sheet to configure a mission. Returns a [MissionConfig] or
/// null if cancelled.
Future<MissionConfig?> showMissionConfigModal(
  BuildContext context,
  MissionInfo info, [
  MissionConfig? existing,
]) async {
  // Missions that need a full-screen picker
  if (info.type == MissionType.objectHunt ||
      info.type == MissionType.petHunt ||
      info.type == MissionType.natureHunt) {
    return _showItemPickerForMission(context, info, existing);
  }

  if (info.type == MissionType.affirmation) {
    final result = await Navigator.push<AffirmationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AffirmationPickerScreen(
          preselected: existing?.selectedAffirmations,
          initialCount: existing?.affirmationCount ?? 1,
        ),
      ),
    );
    if (result == null) return null;
    return MissionConfig(
      type: info.type,
      selectedAffirmations:
          result.affirmations.isEmpty ? null : result.affirmations,
      affirmationCount: result.count,
    );
  }

  if (info.type == MissionType.random) {
    final pool = await Navigator.push<List<MissionType>>(
      context,
      MaterialPageRoute(
        builder: (_) => RandomPoolPickerScreen(
          preselected: existing?.randomPool,
        ),
      ),
    );
    if (pool == null) return null;
    return MissionConfig(
      type: info.type,
      randomPool: pool.isEmpty ? null : pool,
    );
  }

  // Missions with no config
  if (info.type == MissionType.skyPhoto ||
      info.type == MissionType.makeBed ||
      info.type == MissionType.touchGrass) {
    return MissionConfig(type: info.type);
  }

  // Bottom sheet for missions with simple config (stepper-based)
  return showModalBottomSheet<MissionConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _ConfigSheet(info: info, existing: existing),
  );
}

Future<MissionConfig?> _showItemPickerForMission(
  BuildContext context,
  MissionInfo info,
  MissionConfig? existing,
) async {
  final l10n = AppLocalizations.of(context);
  final ItemPickerData data;
  final String title;
  final String subtitle;
  switch (info.type) {
    case MissionType.objectHunt:
      data = objectHuntPickerData;
      title = l10n.itemPickerSelectItems;
      subtitle = l10n.itemPickerRandomItem;
    case MissionType.petHunt:
      data = petHuntPickerData;
      title = l10n.itemPickerSelectPets;
      subtitle = l10n.itemPickerPetsSubtitle;
    case MissionType.natureHunt:
      data = natureHuntPickerData;
      title = l10n.itemPickerSelectNature;
      subtitle = l10n.itemPickerNatureSubtitle;
    default:
      return null;
  }

  final selected = await Navigator.push<List<String>>(
    context,
    MaterialPageRoute(
      builder: (_) => ItemPickerScreen(
        title: title,
        subtitle: subtitle,
        sections: data.sections,
        preselected: existing?.selectedItems,
        showAddCustom: info.type == MissionType.objectHunt,
      ),
    ),
  );
  if (selected == null) return null;
  return MissionConfig(
    type: info.type,
    selectedItems: selected.isEmpty ? null : selected,
  );
}

/// Bottom sheet for push-ups, squats, shake phone, and math config.
class _ConfigSheet extends StatefulWidget {
  final MissionInfo info;
  final MissionConfig? existing;

  const _ConfigSheet({required this.info, this.existing});

  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  late int _repCount;
  late MathDifficulty _mathDifficulty;
  late int _mathProblemCount;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    switch (widget.info.type) {
      case MissionType.pushUps:
        _repCount = e?.repCount ?? 5;
      case MissionType.squats:
        _repCount = e?.repCount ?? 10;
      case MissionType.shakePhone:
        _repCount = e?.repCount ?? 15;
      default:
        _repCount = e?.repCount ?? 5;
    }
    _mathDifficulty = e?.mathDifficulty ?? MathDifficulty.medium;
    _mathProblemCount = e?.mathProblemCount ?? 3;
  }

  MissionConfig _buildConfig() {
    switch (widget.info.type) {
      case MissionType.pushUps:
      case MissionType.squats:
      case MissionType.shakePhone:
        return MissionConfig(type: widget.info.type, repCount: _repCount);
      case MissionType.math:
        return MissionConfig(
          type: widget.info.type,
          mathDifficulty: _mathDifficulty,
          mathProblemCount: _mathProblemCount,
        );
      default:
        return MissionConfig(type: widget.info.type);
    }
  }

  void _preview() {
    final l10n = AppLocalizations.of(context);
    final config = _buildConfig();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => buildDismissScreen(
          config: config,
          alarmId: 'preview',
          nativeAlarmId: 'preview',
          alarmLabel: l10n.missionPickerPreview,
          isPreview: true,
          manageAlarm: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isMath = widget.info.type == MissionType.math;
    final isRep = widget.info.type == MissionType.pushUps ||
        widget.info.type == MissionType.squats ||
        widget.info.type == MissionType.shakePhone;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24.w, 20.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mission icon + name
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: widget.info.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.info.icon,
                color: widget.info.iconColor, size: 30.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            localizedMissionName(l10n, widget.info.type),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            localizedMissionDesc(l10n, widget.info.type),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
          ),
          SizedBox(height: 24.h),

          // Rep stepper (pushUps, squats, shakePhone)
          if (isRep) ...[
            Text(
              widget.info.type == MissionType.shakePhone
                  ? l10n.missionConfigNumberOfShakes
                  : l10n.missionConfigNumberOfReps,
              style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
            ),
            SizedBox(height: 12.h),
            _Stepper(
              value: _repCount,
              min: 1,
              max: 100,
              onChanged: (v) => setState(() => _repCount = v),
            ),
            SizedBox(height: 24.h),
          ],

          // Math config
          if (isMath) ...[
            Text(
              l10n.missionConfigNumberOfProblems,
              style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
            ),
            SizedBox(height: 12.h),
            _Stepper(
              value: _mathProblemCount,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _mathProblemCount = v),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.missionConfigDifficulty,
              style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
            ),
            SizedBox(height: 12.h),
            Row(
              children: MathDifficulty.values.map((d) {
                final selected = _mathDifficulty == d;
                final label = switch (d) {
                  MathDifficulty.easy => l10n.missionConfigEasy,
                  MathDifficulty.medium => l10n.missionConfigMedium,
                  MathDifficulty.hard => l10n.missionConfigHard,
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: withHaptic(() => setState(() => _mathDifficulty = d)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                          right: d != MathDifficulty.hard ? 8.w : 0),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.orange : c.background,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
          ],

          // Preview + Confirm buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: withHaptic(_preview),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    side: BorderSide(color: c.separator),
                  ),
                  child: Text(
                    l10n.missionPickerPreview,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: withHaptic(() => Navigator.pop(context, _buildConfig())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.missionConfigChoose,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple +/- stepper widget.
class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepButton(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
          c: c,
        ),
        SizedBox(width: 24.w),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
          ),
        ),
        SizedBox(width: 24.w),
        _stepButton(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
          c: c,
        ),
      ],
    );
  }

  Widget _stepButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return GestureDetector(
      onTap: enabled ? withHaptic(onTap) : null,
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: enabled ? AppColors.orange : c.separator,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : c.textSecondary,
          size: 22.sp,
        ),
      ),
    );
  }
}
