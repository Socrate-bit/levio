import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../shared/widgets/day_selector_row.dart';
import '../../../shared/widgets/time_picker_sheet.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../../shared/theme/app_theme.dart';
import '../../missions/screens/mission_picker_screen.dart';
import '../../missions/widgets/mission_config_modal.dart';
import 'sound_picker_screen.dart';

class AlarmFormScreen extends StatefulWidget {
  /// If non-null, the form is in edit mode for this alarm.
  final AppAlarmEntry? alarm;

  /// When false, the mission picker is hidden.
  final bool showMission;

  const AlarmFormScreen({super.key, this.alarm, this.showMission = true});

  @override
  State<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends State<AlarmFormScreen> {
  late final TextEditingController _nameCtrl;
  late TimeOfDay _time;
  late bool _isScheduled;
  late List<bool> _repeatDays;
  late List<MissionConfig> _missions;
  late String _soundId;
  late String _soundName;
  late bool _isSleep;
  late bool _gentle;
  late bool _reminderEnabled;
  late int _reminderMinutes;

  bool get _isEditing => widget.alarm != null;

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _missions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    if (a != null) {
      _nameCtrl = TextEditingController(text: a.name);
      _time = TimeOfDay(hour: a.dateTime.hour, minute: a.dateTime.minute);
      _isScheduled = !a.isOneTime;
      _repeatDays = List.from(a.repeatDays);
      _missions = List.from(a.missions);
      _soundId = a.soundId;
      _soundName = _soundIdToName(a.soundId);
      _isSleep = a.isSleep;
      _gentle = a.gentle;
      _reminderEnabled = a.reminderEnabled;
      _reminderMinutes = a.reminderMinutesBefore;
    } else {
      // Create mode: use saved defaults from settings
      final alarmCount = context.read<AlarmCubit>().state.alarms.length;
      final settings = context.read<SettingsCubit>().state;
      _nameCtrl = TextEditingController(text: 'Alarm #${alarmCount + 1}');
      _time = const TimeOfDay(hour: 8, minute: 0);
      _isScheduled = true;
      _repeatDays = [false, true, true, true, true, true, false];
      _missions = settings.defaultMission != MissionType.none
          ? [MissionConfig(type: settings.defaultMission)]
          : [];
      _soundId = settings.defaultSoundId;
      _soundName = settings.defaultSoundName;
      _isSleep = false;
      _gentle = false;
      _reminderEnabled = false;
      _reminderMinutes = 15;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _soundIdToName(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Short summary text for a mission config.
  String _configSummary(MissionConfig config) {
    switch (config.type) {
      case MissionType.pushUps:
        return '${config.repCount ?? 5} reps';
      case MissionType.squats:
        return '${config.repCount ?? 10} reps';
      case MissionType.shakePhone:
        return '${config.repCount ?? 15} shakes';
      case MissionType.math:
        final diff = switch (config.mathDifficulty ?? MathDifficulty.medium) {
          MathDifficulty.easy => 'Easy',
          MathDifficulty.medium => 'Medium',
          MathDifficulty.hard => 'Hard',
        };
        return '${config.mathProblemCount ?? 3} problems · $diff';
      case MissionType.objectHunt:
        final count = config.selectedItems?.length ?? 0;
        return count > 0 ? '$count items' : 'All items';
      case MissionType.petHunt:
        final count = config.selectedItems?.length ?? 0;
        return count > 0 ? '$count pets' : 'All pets';
      case MissionType.natureHunt:
        final count = config.selectedItems?.length ?? 0;
        return count > 0 ? '$count items' : 'All items';
      case MissionType.affirmation:
        final count = config.selectedAffirmations?.length ?? 0;
        return count > 0 ? '$count affirmations' : 'All affirmations';
      case MissionType.routine:
        final count =
            config.selectedItems?.length ?? routinePresetSteps.length;
        return AppLocalizations.of(context).routineStepsCount(count);
      case MissionType.random:
        final count = config.randomPool?.length ?? 0;
        return count == 0 ? 'All missions' : '$count in pool';
      default:
        return '';
    }
  }

  Future<void> _addMission() async {
    final config = await Navigator.push<MissionConfig>(
      context,
      MaterialPageRoute(builder: (_) => const MissionPickerScreen()),
    );
    if (config != null && mounted) {
      setState(() => _missions.add(config));
    }
  }

  Future<void> _editMission(int index) async {
    final existing = _missions[index];
    final info = missionInfoFor(existing.type);
    final config = await showMissionConfigModal(context, info, existing);
    if (config != null && mounted) {
      setState(() => _missions[index] = config);
    }
  }

  Future<void> _showTimePicker() async {
    final picked = await showTimePickerSheet(context, initial: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  /// Bottom-sheet picker for the reminder lead time (5–60 min, step 5).
  void _showReminderPicker(AppColors c) {
    final l10n = AppLocalizations.of(context);
    const options = [5, 10, 15, 20, 30, 45, 60];
    var index = options.indexOf(_reminderMinutes);
    if (index < 0) index = 2; // default to 15 min
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Row(
                children: [
                  Text(
                    l10n.alarmFormReminder,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(ctx)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        l10n.alarmFormDone,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200.h,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: index),
                itemExtent: 40.h,
                onSelectedItemChanged: (i) =>
                    setState(() => _reminderMinutes = options[i]),
                children: options
                    .map(
                      (m) => Center(
                        child: Text(
                          l10n.alarmFormReminderBefore(m),
                          style: TextStyle(
                            fontSize: 22.sp,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: withHaptic(() => Navigator.pop(context)),
                      child: Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: c.card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20.sp,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _isEditing
                              ? l10n.alarmFormEditAlarm
                              : l10n.alarmFormNewAlarm,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40.w),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Sleep / Wake-up kind toggle (sun / moon)
              _FormCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _TogglePill(
                        label: l10n.alarmFormWakeUp,
                        icon: Icons.wb_sunny,
                        selected: !_isSleep,
                        onTap: () => setState(() => _isSleep = false),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _TogglePill(
                        label: l10n.alarmFormSleep,
                        icon: Icons.nightlight_round,
                        selected: _isSleep,
                        onTap: () => setState(() => _isSleep = true),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Name field
              _FormCard(
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 17.sp, color: c.textPrimary),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.alarmFormAlarmName,
                    hintStyle: TextStyle(color: c.textSecondary),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Alarm time — opens CupertinoPicker modal
              _FormCard(
                onTap: _showTimePicker,
                child: Row(
                  children: [
                    Text(
                      l10n.alarmFormAlarmTime,
                      style: TextStyle(fontSize: 17.sp, color: c.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      _time.format(context),
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.chevron_right, size: 22.sp, color: c.textSecondary),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Scheduled / One-time toggle
              _FormCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _TogglePill(
                        label: l10n.alarmFormScheduled,
                        selected: _isScheduled,
                        onTap: () => setState(() => _isScheduled = true),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _TogglePill(
                        label: l10n.alarmFormOneTime,
                        selected: !_isScheduled,
                        onTap: () => setState(() => _isScheduled = false),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Repeat days
              if (_isScheduled) ...[
                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.alarmFormRepeatOn,
                        style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
                      ),
                      SizedBox(height: 12.h),
                      DaySelectorRow(
                        days: _repeatDays,
                        onChanged: (next) =>
                            setState(() => _repeatDays = next),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              // Missions (up to 3)
              if (widget.showMission) ...[
                // Existing missions
                for (int i = 0; i < _missions.length; i++) ...[
                  _buildMissionCard(i, c, l10n),
                  SizedBox(height: 12.h),
                ],
                // Add mission button (max 3)
                if (_missions.length < 3)
                  _missions.isEmpty
                      ? _FormCard(
                          onTap: _addMission,
                          child: Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: c.background,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 20.sp,
                                  color: c.textSecondary,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.alarmFormAddMission(_missions.length),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      l10n.alarmFormStackMissions,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.chevron_right, color: c.textSecondary),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: withHaptic(_addMission),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: c.separator,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 18.sp, color: c.textSecondary),
                                SizedBox(width: 6.w),
                                Text(
                                  l10n.alarmFormAddMission(_missions.length),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                SizedBox(height: 12.h),
              ],
              // Sound
              _FormCard(
                onTap: () async {
                  final result = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SoundPickerScreen(),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _soundId = result['id']!;
                      _soundName = result['name']!;
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 24.sp,
                      color: c.textSecondary,
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.alarmFormSound,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: c.textSecondary,
                          ),
                        ),
                        Text(
                          _soundName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: c.textSecondary),
                  ],
                ),
              ),
              // Sleep-only settings: ring style + bedtime reminder
              if (_isSleep) ...[
                SizedBox(height: 12.h),
                _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.alarmFormRingStyle,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: c.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _TogglePill(
                              label: l10n.alarmFormGentle,
                              selected: _gentle,
                              onTap: () => setState(() => _gentle = true),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _TogglePill(
                              label: l10n.alarmFormLoud,
                              selected: !_gentle,
                              onTap: () => setState(() => _gentle = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                _FormCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.alarmFormReminder,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                                Text(
                                  l10n.alarmFormReminderHint,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _reminderEnabled,
                            activeTrackColor: AppColors.orange,
                            onChanged: (v) =>
                                setState(() => _reminderEnabled = v),
                          ),
                        ],
                      ),
                      if (_reminderEnabled)
                        GestureDetector(
                          onTap: withHaptic(() => _showReminderPicker(c)),
                          child: Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 20.sp,
                                  color: c.textSecondary,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  l10n.alarmFormReminderBefore(
                                    _reminderMinutes,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: c.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: ElevatedButton(
                onPressed: _canSave ? withHaptic(() => _save(context)) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave ? AppColors.orange : c.separator,
                  foregroundColor: _canSave ? Colors.white : c.textSecondary,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing
                      ? l10n.alarmFormUpdateAlarm
                      : l10n.alarmFormSaveAlarm,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for an existing mission at [index].
  Widget _buildMissionCard(int index, AppColors c, AppLocalizations l10n) {
    final config = _missions[index];
    final info = missionInfoFor(config.type);
    final summary = _configSummary(config);
    return _FormCard(
      onTap: () => _editMission(index),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: info.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 20.sp, color: info.iconColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedMissionName(l10n, config.type),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  summary.isNotEmpty
                      ? '${l10n.alarmFormMissionIndex(index + 1)} · $summary'
                      : l10n.alarmFormMissionIndex(index + 1),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: withHaptic(() => setState(() => _missions.removeAt(index))),
            child: Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: c.background,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 15.sp, color: c.textSecondary),
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
    final entry = AppAlarmEntry(
      id: widget.alarm?.id ?? '',
      dateTime: dt,
      missions: _missions,
      name: _nameCtrl.text.trim(),
      soundId: _soundId,
      repeatDays: _repeatDays,
      isOneTime: !_isScheduled,
      isSleep: _isSleep,
      // Gentle ring and reminder only apply to sleep alarms.
      gentle: _isSleep && _gentle,
      reminderEnabled: _isSleep && _reminderEnabled,
      reminderMinutesBefore: _reminderMinutes,
    );

    final cubit = context.read<AlarmCubit>();
    if (_isEditing) {
      cubit.editAlarm(widget.alarm!, entry);
    } else {
      cubit.addAlarm(entry);
    }
    Navigator.pop(context);
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FormCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: child,
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = selected ? Colors.white : c.textSecondary;
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : c.background,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18.sp, color: fg),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
