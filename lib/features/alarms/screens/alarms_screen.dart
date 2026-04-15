import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../../shared/theme/app_theme.dart';
import 'alarm_form_screen.dart';
import '../../missions/models/mission_config.dart';

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
    final c = AppColors.of(context);
    return BlocBuilder<AlarmCubit, AlarmState>(
      builder: (context, state) {
        final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 60;
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(
            title: const Text('Alarms'),
          ),
          body: Stack(
            children: [
              state.alarms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⏰', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(
                            'No alarms yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap + to create your first alarm',
                            style: TextStyle(
                                fontSize: 14, color: c.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 72),
                      itemCount: state.alarms.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _AlarmCard(alarm: state.alarms[i]),
                    ),
              Positioned(
                right: 20,
                bottom: bottomPadding + 10,
                child: _AddAlarmFab(
                  onNormal: () => _addNormalAlarm(context),
                  onMission: () => _addMissionAlarm(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNormalAlarm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AlarmCubit>(),
          child: const AlarmFormScreen(showMission: false),
        ),
      ),
    );
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
          backgroundColor: AppColors.orange,
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
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
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
    final c = AppColors.of(context);
    final t = alarm.dateTime;
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final isPM = t.hour >= 12;
    final dayStr = alarm.isOneTime ? 'One-time' : _daysLabel(alarm.repeatDays);

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
          color: c.card,
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
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$h:$m',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: c.textPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    isPM ? 'PM' : 'AM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
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
                  alarm.name.isNotEmpty ? alarm.name : 'Alarm #1',
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                if (alarm.missions.isNotEmpty) ...[
                  Text(' · ', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                  _StackedMissionIcons(missions: alarm.missions),
                  const SizedBox(width: 6),
                  Text(
                    alarm.missions.length == 1
                        ? missionInfoFor(alarm.missions.first.type).name
                        : '${alarm.missions.length} Missions',
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      context.read<AlarmCubit>().removeAlarm(alarm.id),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: c.textSecondary),
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

/// Stacked/overlapping mission icons (like avatar groups).
class _StackedMissionIcons extends StatelessWidget {
  final List<MissionConfig> missions;
  const _StackedMissionIcons({required this.missions});

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    const overlap = 8.0;
    final width = size + (missions.length - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < missions.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: missionInfoFor(missions[i].type).iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.of(context).card,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  missionInfoFor(missions[i].type).icon,
                  size: 10,
                  color: missionInfoFor(missions[i].type).iconColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
