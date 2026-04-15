import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../alarms/screens/alarm_form_screen.dart';
import '../../alarms/screens/sound_picker_screen.dart';
import '../../missions/screens/mission_picker_screen.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
import '../../wakeup/screens/sessions_list_screen.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => HomeCubit()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          _TopBar(streak: state.currentStreak),
                          const SizedBox(height: 20),
                          _WeekRow(weekDays: state.weekDays),
                          const SizedBox(height: 24),
                          BlocBuilder<AlarmCubit, AlarmState>(
                            builder: (context, alarmState) {
                              final alarms = [...alarmState.alarms]
                                ..sort(
                                  (a, b) => a.dateTime.compareTo(b.dateTime),
                                );
                              final next = alarms
                                  .where((a) => a.isEnabled)
                                  .firstOrNull;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.homeNextWakeUp,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (next != null)
                                    _NextAlarmCard(alarm: next)
                                  else
                                    _NoAlarmCard(),
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                          ),
                          if (state.lastSession != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.homeTodaysWakeup,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: c.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SessionsListScreen(),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.homeSeeAll,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _WakeupCard(
                              session: state.lastSession!,
                              wakeupNumber: state.totalWakeups,
                            ),
                          ] else ...[
                            _EmptyWakeupCard(),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final int streak;
  const _TopBar({required this.streak});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Image.asset('assets/icon.png', width: 32, height: 32),
        const SizedBox(width: 6),
        Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => BottomNavShell.of(context)?.navigateTo(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DayStatus> weekDays;
  const _WeekRow({required this.weekDays});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.daySingleS, l10n.daySingleM, l10n.daySingleT, l10n.daySingleW, l10n.daySingleT, l10n.daySingleF, l10n.daySingleS];
    final todayIndex = DateTime.now().weekday % 7; // 0=Sun
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final isToday = i == todayIndex;
        final status = weekDays.length > i ? weekDays[i] : DayStatus.none;
        return Column(
          children: [
            Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? c.textPrimary : c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status == DayStatus.none ? c.separator : Colors.transparent,
                border: switch (status) {
                  DayStatus.done => Border.all(color: AppColors.orange, width: 2),
                  DayStatus.frozen => Border.all(color: AppColors.blue, width: 2),
                  DayStatus.none => null,
                },
              ),
              child: switch (status) {
                DayStatus.done => const Icon(Icons.check, size: 18, color: AppColors.orange),
                DayStatus.frozen => const Icon(Icons.ac_unit, size: 16, color: AppColors.blue),
                DayStatus.none => null,
              },
            ),
          ],
        );
      }),
    );
  }
}

class _NoAlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AlarmCubit>(),
            child: const AlarmFormScreen(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.orange.withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_alarm_rounded,
                color: AppColors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNoActiveAlarm,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeNoActiveAlarmHint,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NextAlarmCard extends StatefulWidget {
  final AppAlarmEntry alarm;
  const _NextAlarmCard({required this.alarm});

  @override
  State<_NextAlarmCard> createState() => _NextAlarmCardState();
}

class _NextAlarmCardState extends State<_NextAlarmCard> {
  Future<void> _pickMission() async {
    final config = await Navigator.push<MissionConfig>(
      context,
      MaterialPageRoute(builder: (_) => const MissionPickerScreen()),
    );
    if (config == null || !mounted) return;
    // Replace or add mission at index 0
    final updated = List<MissionConfig>.from(widget.alarm.missions);
    if (updated.isEmpty) {
      updated.add(config);
    } else {
      updated[0] = config;
    }
    context
        .read<AlarmCubit>()
        .editAlarm(widget.alarm, widget.alarm.copyWith(missions: updated));
  }

  Future<void> _pickSound() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const SoundPickerScreen()),
    );
    if (result == null || !mounted) return;
    context
        .read<AlarmCubit>()
        .editAlarm(widget.alarm, widget.alarm.copyWith(soundId: result['id']));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final alarm = widget.alarm;
    final now = DateTime.now();
    final diff = alarm.dateTime.difference(now);
    final hoursLeft = diff.inHours;
    final minsLeft = diff.inMinutes % 60;
    final timeStr = _formatTime(alarm.dateTime);
    final isPM = alarm.dateTime.hour >= 12;
    final firstMission = alarm.missions.isNotEmpty
        ? missionInfoFor(alarm.missions.first.type)
        : missionInfoFor(MissionType.none);

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
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diff.isNegative
                  ? l10n.homeToday
                  : diff.inHours < 24
                  ? l10n.homeToday
                  : l10n.homeTomorrow,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    isPM ? 'pm' : 'am',
                    style: TextStyle(fontSize: 16, color: c.textSecondary),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: alarm.isEnabled,
                  activeThumbColor: AppColors.green,
                  onChanged: (_) {},
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: c.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  diff.isNegative
                      ? l10n.homePastAlarm
                      : l10n.homeRingsIn(hoursLeft, minsLeft),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniInfoCard(
                  icon: firstMission.icon,
                  iconColor: firstMission.iconColor,
                  label: l10n.homeMission,
                  value: alarm.missions.length > 1
                      ? '${alarm.missions.length} Missions'
                      : localizedMissionName(l10n, alarm.missions.isNotEmpty ? alarm.missions.first.type : MissionType.none),
                  onTap: _pickMission,
                ),
                const SizedBox(width: 10),
                _MiniInfoCard(
                  icon: Icons.music_note,
                  iconColor: const Color(0xFFFFCC00),
                  label: l10n.homeSound,
                  value: alarm.soundId == 'default' ? l10n.generalDefault : localizedSoundName(l10n, alarm.soundId),
                  onTap: _pickSound,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _MiniInfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Icon(icon, size: 22, color: iconColor),
          ],
        ),
      ),
      ),
    );
  }
}

class _WakeupCard extends StatelessWidget {
  final dynamic session;
  final int wakeupNumber;
  const _WakeupCard({required this.session, required this.wakeupNumber});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final ts = session.timestamp as DateTime;
    final hour = ts.hour > 12 ? ts.hour - 12 : ts.hour;
    final isPM = ts.hour >= 12;
    final timeStr =
        '$hour:${ts.minute.toString().padLeft(2, '0')} ${isPM ? 'pm' : 'am'}';
    final dateStr = '${localizedMonth(l10n, ts.month)} ${ts.day}';
    final missionType = session.missionType;
    final label = missionType != null
        ? localizedMissionName(l10n, missionType as MissionType)
        : 'Alarm';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient color area with sun centered inside it
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE0A3), Color(0xFFB8D4E8)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C3B00),
                      ),
                    ),
                  ),
                ),
                const Center(child: Text('🌞', style: TextStyle(fontSize: 60))),
              ],
            ),
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: c.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.wb_sunny,
                      color: AppColors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      Text(
                        '#$wakeupNumber',
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}

class _EmptyWakeupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('🌅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              l10n.homeNoWakeupsYet,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.homeSetAlarmToStart,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
