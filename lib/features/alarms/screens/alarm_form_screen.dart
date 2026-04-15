import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  bool get _isEditing => widget.alarm != null;

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

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
        final diff = switch (config.mathDifficulty ?? MathDifficulty.easy) {
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

  void _showTimePicker(AppColors c) {
    final l10n = AppLocalizations.of(context);
    var hour = _time.hour;
    var minute = _time.minute;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(l10n.alarmFormSetTime,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() =>
                          _time = TimeOfDay(hour: hour, minute: minute));
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(l10n.alarmFormDone,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController:
                          FixedExtentScrollController(initialItem: hour),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => hour = i,
                      children: List.generate(
                        24,
                        (i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: TextStyle(
                                fontSize: 22, color: c.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(':',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary)),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController:
                          FixedExtentScrollController(initialItem: minute),
                      itemExtent: 40,
                      onSelectedItemChanged: (i) => minute = i,
                      children: List.generate(
                        60,
                        (i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: TextStyle(
                                fontSize: 22, color: c.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
    final dayLabels = [
      l10n.daySingleS, l10n.daySingleM, l10n.daySingleT, l10n.daySingleW,
      l10n.daySingleT, l10n.daySingleF, l10n.daySingleS,
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
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
                      child: Icon(Icons.close,
                          size: 18, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _isEditing ? l10n.alarmFormEditAlarm : l10n.alarmFormNewAlarm,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Name field
                    _FormCard(
                      child: TextField(
                        controller: _nameCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 16,
                          color: c.textPrimary,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.alarmFormAlarmName,
                          hintStyle:
                              TextStyle(color: c.textSecondary),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Alarm time — opens CupertinoPicker modal
                    _FormCard(
                      onTap: () => _showTimePicker(c),
                      child: Row(
                        children: [
                          Text(
                            l10n.alarmFormAlarmTime,
                            style: TextStyle(
                                fontSize: 16, color: c.textPrimary),
                          ),
                          const Spacer(),
                          Text(
                            _time.format(context),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 20, color: c.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Scheduled / One-time toggle
                    _FormCard(
                      child: Row(
                        children: [
                          _TogglePill(
                            label: l10n.alarmFormScheduled,
                            selected: _isScheduled,
                            onTap: () =>
                                setState(() => _isScheduled = true),
                          ),
                          const SizedBox(width: 8),
                          _TogglePill(
                            label: l10n.alarmFormOneTime,
                            selected: !_isScheduled,
                            onTap: () =>
                                setState(() => _isScheduled = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Repeat days
                    if (_isScheduled) ...[
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.alarmFormRepeatOn,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: c.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (i) {
                                final selected = _repeatDays[i];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _repeatDays = List.from(_repeatDays)
                                        ..[i] = !selected;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? AppColors.orange
                                          : c.background,
                                    ),
                                    child: Center(
                                      child: Text(
                                        dayLabels[i],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : c.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Missions (up to 3)
                    if (widget.showMission) ...[
                      // Existing missions
                      for (int i = 0; i < _missions.length; i++) ...[
                        _buildMissionCard(i, c, l10n),
                        const SizedBox(height: 12),
                      ],
                      // Add mission button (max 3)
                      if (_missions.length < 3)
                        _FormCard(
                          onTap: _addMission,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c.background,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add,
                                    size: 18, color: c.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.alarmFormAddMission(_missions.length),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    l10n.alarmFormStackMissions,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  color: c.textSecondary),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    // Sound
                    _FormCard(
                      onTap: () async {
                        final result =
                            await Navigator.push<Map<String, String>>(
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
                          Icon(Icons.notifications_outlined,
                              size: 22, color: c.textSecondary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.alarmFormSound,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: c.textSecondary)),
                              Text(
                                _soundName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              color: c.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: _canSave ? () => _save(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canSave ? c.textPrimary : c.separator,
                  foregroundColor: _canSave
                      ? c.background
                      : c.textSecondary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? l10n.alarmFormUpdateAlarm : l10n.alarmFormSaveAlarm,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
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
      highlighted: true,
      onTap: () => _editMission(index),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.alarmFormMissionIndex(index + 1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                Text(
                  localizedMissionName(l10n, config.type),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _missions.removeAt(index)),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              color: Colors.white.withAlpha(180)),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    final entry = AppAlarmEntry(
      id: widget.alarm?.id ?? '',
      dateTime: dt,
      missions: _missions,
      name: _nameCtrl.text.trim(),
      soundId: _soundId,
      repeatDays: _repeatDays,
      isOneTime: !_isScheduled,
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
  final bool highlighted;

  const _FormCard({required this.child, this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.orange : c.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppColors.orange.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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

  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : c.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
