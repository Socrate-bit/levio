import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../../shared/theme/app_theme.dart';
import '../../missions/screens/mission_picker_screen.dart';
import 'sound_picker_screen.dart';

class AlarmFormScreen extends StatefulWidget {
  const AlarmFormScreen({super.key});

  @override
  State<AlarmFormScreen> createState() => _AlarmFormScreenState();
}

class _AlarmFormScreenState extends State<AlarmFormScreen> {
  final _nameCtrl = TextEditingController(text: 'Alarm #1');
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _isScheduled = true;
  List<bool> _repeatDays = [false, true, true, true, true, true, false];
  MissionType? _mission;
  String _soundId = 'default';
  String _soundName = 'Default';

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Mission Alarm',
                        style: TextStyle(
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
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Alarm name',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Alarm time
                    _FormCard(
                      child: Row(
                        children: [
                          const Text(
                            'Alarm Time',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.textPrimary),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
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
                            onTap: () => setState(() => _isScheduled = true),
                          ),
                          const SizedBox(width: 8),
                          _TogglePill(
                            label: '📅  One-time',
                            selected: !_isScheduled,
                            onTap: () => setState(() => _isScheduled = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Repeat days
                    if (_isScheduled)
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Repeat on:',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          ? AppColors.textPrimary
                                          : AppColors.background,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _dayLabels[i],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.textSecondary,
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
                    if (_isScheduled) const SizedBox(height: 12),
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
                          setState(() => _mission = picked);
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                size: 18, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mission',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                _mission != null
                                    ? missionInfoFor(_mission!).name
                                    : 'Tap to add a mission',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          const Icon(Icons.notifications_outlined,
                              size: 22, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sound',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
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
                          const Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sleep Better
                    _FormCard(
                      child: Row(
                        children: [
                          const Text('🌙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          const Text(
                            'Sleep Better',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
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
                  backgroundColor: _canSave
                      ? AppColors.textPrimary
                      : AppColors.separator,
                  foregroundColor: _canSave ? Colors.white : AppColors.textSecondary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Alarm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
    final entry = AppAlarmEntry(
      id: '',
      dateTime: dt,
      missionType: _mission ?? MissionType.shakePhone,
      name: _nameCtrl.text.trim(),
      soundId: _soundId,
      repeatDays: _repeatDays,
      isOneTime: !_isScheduled,
    );
    context.read<AlarmCubit>().addAlarm(entry);
    Navigator.pop(context);
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FormCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
