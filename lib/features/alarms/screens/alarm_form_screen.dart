import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../../shared/theme/app_theme.dart';
import '../../missions/screens/mission_picker_screen.dart';
import 'sound_picker_screen.dart';

class AlarmFormScreen extends StatefulWidget {
  /// If non-null, the form is in edit mode for this alarm.
  final AppAlarmEntry? alarm;

  const AlarmFormScreen({super.key, this.alarm});

  @override
  State<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends State<AlarmFormScreen> {
  late final TextEditingController _nameCtrl;
  late TimeOfDay _time;
  late bool _isScheduled;
  late List<bool> _repeatDays;
  late MissionType? _mission;
  late String _soundId;
  late String _soundName;
  late MathDifficulty _mathDifficulty;
  late TextEditingController _customObjectCtrl;

  bool get _isEditing => widget.alarm != null;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _diffLabels = ['Easy', 'Medium', 'Hard'];

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    if (a != null) {
      // Edit mode: pre-fill from existing alarm
      _nameCtrl = TextEditingController(text: a.name);
      _time = TimeOfDay(hour: a.dateTime.hour, minute: a.dateTime.minute);
      _isScheduled = !a.isOneTime;
      _repeatDays = List.from(a.repeatDays);
      _mission = a.missionType;
      _soundId = a.soundId;
      _soundName = _soundIdToName(a.soundId);
      _mathDifficulty = a.mathDifficulty;
      _customObjectCtrl = TextEditingController(text: a.customObject ?? '');
    } else {
      // Create mode: defaults + auto-increment name
      final alarmCount =
          context.read<AlarmCubit>().state.alarms.length;
      _nameCtrl = TextEditingController(text: 'Alarm #${alarmCount + 1}');
      _time = const TimeOfDay(hour: 8, minute: 0);
      _isScheduled = true;
      _repeatDays = [false, true, true, true, true, true, false];
      _mission = null;
      _soundId = 'default';
      _soundName = 'Default';
      _mathDifficulty = MathDifficulty.easy;
      _customObjectCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customObjectCtrl.dispose();
    super.dispose();
  }

  String _soundIdToName(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
                        _isEditing ? 'Edit Alarm' : 'Mission Alarm',
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
                          hintText: 'Alarm name',
                          hintStyle:
                              TextStyle(color: c.textSecondary),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Alarm time
                    _FormCard(
                      child: Row(
                        children: [
                          Text(
                            'Alarm Time',
                            style: TextStyle(
                                fontSize: 16, color: c.textPrimary),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _time,
                              );
                              if (picked != null) {
                                setState(() => _time = picked);
                              }
                            },
                            child: Text(
                              _time.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Scheduled / One-time toggle
                    _FormCard(
                      child: Row(
                        children: [
                          _TogglePill(
                            label: '↻  Scheduled',
                            selected: _isScheduled,
                            onTap: () =>
                                setState(() => _isScheduled = true),
                          ),
                          const SizedBox(width: 8),
                          _TogglePill(
                            label: '📅  One-time',
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
                              'Repeat on:',
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
                                          ? c.textPrimary
                                          : c.background,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _dayLabels[i],
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
                    // Mission
                    _FormCard(
                      onTap: () async {
                        final picked = await Navigator.push<MissionType>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MissionPickerScreen(),
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _mission = picked;
                            // Reset mission-specific fields on change
                            if (picked != MissionType.math) {
                              _mathDifficulty = MathDifficulty.easy;
                            }
                            if (picked != MissionType.objectHunt) {
                              _customObjectCtrl.clear();
                            }
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.background,
                              shape: BoxShape.circle,
                            ),
                            child: _mission != null
                                ? Icon(
                                    missionInfoFor(_mission!).icon,
                                    size: 18,
                                    color: missionInfoFor(_mission!).iconColor,
                                  )
                                : Icon(Icons.add,
                                    size: 18,
                                    color: c.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mission',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary),
                              ),
                              Text(
                                _mission != null
                                    ? missionInfoFor(_mission!).name
                                    : 'Tap to add a mission',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: c.textPrimary,
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

                    // Math difficulty picker
                    if (_mission == MissionType.math) ...[
                      const SizedBox(height: 12),
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Difficulty',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: c.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(
                                MathDifficulty.values.length,
                                (i) {
                                  final diff = MathDifficulty.values[i];
                                  final selected = _mathDifficulty == diff;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _mathDifficulty = diff),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        margin: EdgeInsets.only(
                                            right: i < 2 ? 8 : 0),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.orange
                                              : c.background,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _diffLabels[i],
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
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Custom object field for objectHunt
                    if (_mission == MissionType.objectHunt) ...[
                      const SizedBox(height: 12),
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Object (optional)',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: c.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _customObjectCtrl,
                              style: TextStyle(
                                  fontSize: 15, color: c.textPrimary),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'e.g. coffee mug (blank = random)',
                                hintStyle:
                                    TextStyle(color: c.textSecondary),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
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
                              Text('Sound',
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
                      ? Colors.white
                      : c.textSecondary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? 'Update Alarm' : 'Save Alarm',
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

  void _save(BuildContext context) {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    final customObj = _customObjectCtrl.text.trim();
    final entry = AppAlarmEntry(
      id: widget.alarm?.id ?? '',
      dateTime: dt,
      missionType: _mission ?? MissionType.shakePhone,
      name: _nameCtrl.text.trim(),
      soundId: _soundId,
      repeatDays: _repeatDays,
      isOneTime: !_isScheduled,
      mathDifficulty: _mathDifficulty,
      customObject: customObj.isEmpty ? null : customObj,
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
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
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
          color: selected ? c.textPrimary : c.background,
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
