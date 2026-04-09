import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../../shared/theme/app_theme.dart';
import 'alarm_form_screen.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AlarmCubit, AlarmState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Alarms'),
          ),
          floatingActionButton: _AddAlarmFab(
            onNormal: () => _addNormalAlarm(context),
            onMission: () => _addMissionAlarm(context),
          ),
          body: state.alarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⏰', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      const Text(
                        'No alarms yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap + to create your first alarm',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: state.alarms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) =>
                      _AlarmCard(alarm: state.alarms[i]),
                ),
        );
      },
    );
  }

  Future<void> _addNormalAlarm(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null || !context.mounted) return;
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
    context.read<AlarmCubit>().addAlarm(AppAlarmEntry(
          id: '',
          dateTime: dt,
          missionType: MissionType.shakePhone,
          name: 'Normal Alarm',
        ));
  }

  void _addMissionAlarm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AlarmCubit>(),
          child: const AlarmFormScreen(),
        ),
      ),
    );
  }
}

class _AddAlarmFab extends StatefulWidget {
  final VoidCallback onNormal;
  final VoidCallback onMission;

  const _AddAlarmFab({required this.onNormal, required this.onMission});

  @override
  State<_AddAlarmFab> createState() => _AddAlarmFabState();
}

class _AddAlarmFabState extends State<_AddAlarmFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotate = Tween<double>(begin: 0, end: 0.125).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _PopupOption(
            label: 'Mission Alarm',
            subtitle: 'Finish a task first',
            onTap: () {
              _toggle();
              widget.onMission();
            },
          ),
          const SizedBox(height: 8),
          _PopupOption(
            label: 'Normal Alarm',
            subtitle: 'Just an alarm',
            onTap: () {
              _toggle();
              widget.onNormal();
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          backgroundColor:
              _open ? AppColors.textPrimary : AppColors.textPrimary,
          foregroundColor: Colors.white,
          onPressed: _toggle,
          child: RotationTransition(
            turns: _rotate,
            child: Icon(_open ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }
}

class _PopupOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PopupOption({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AppAlarmEntry alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final t = alarm.dateTime;
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final isPM = t.hour >= 12;
    final info = missionInfoFor(alarm.missionType);
    final dayStr = _daysLabel(alarm.repeatDays);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AlarmCubit>(),
            child: AlarmFormScreen(alarm: alarm),
          ),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayStr,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$h:$m',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  isPM ? 'PM' : 'AM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: alarm.isEnabled,
                activeThumbColor: AppColors.green,
                onChanged: (val) =>
                    context.read<AlarmCubit>().toggleAlarm(alarm.id, val),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                alarm.name.isNotEmpty
                    ? '${alarm.name} · '
                    : 'Alarm #1 · ',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(info.icon, size: 13, color: info.iconColor),
              const SizedBox(width: 4),
              Text(
                info.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    context.read<AlarmCubit>().removeAlarm(alarm.id),
                child: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _daysLabel(List<bool> days) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (days.every((d) => d)) return 'Every day';
    if (days.every((d) => !d)) return 'One-time';

    final selected = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) selected.add(labels[i]);
    }
    // Check weekdays
    if (days[1] && days[2] && days[3] && days[4] && days[5] &&
        !days[0] && !days[6]) {
      return 'Mon, Tue, Wed, Thu, Fri';
    }
    return selected.join(', ');
  }
}
