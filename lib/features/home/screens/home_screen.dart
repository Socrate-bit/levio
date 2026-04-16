import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../alarms/screens/alarm_form_screen.dart';
import '../../alarms/screens/sound_picker_screen.dart';
import '../../missions/screens/mission_picker_screen.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
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
            bottom: false,
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          BlocBuilder<AlarmCubit, AlarmState>(
                            builder: (context, alarmState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.alarmsTitle,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (alarmState.alarms.isEmpty)
                                    _EmptyAlarmsCard()
                                  else
                                    ...alarmState.alarms.map(
                                      (alarm) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _AlarmCard(alarm: alarm),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 120),
                        ],
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
        Image.asset('assets/icon.png', width: 36, height: 36),
        const SizedBox(width: 8),
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
          onTap: withHaptic(() => BottomNavShell.of(context)?.navigateTo(1)),
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
                Image.asset('assets/streaks.png', width: 20, height: 20),
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
    final now = DateTime.now();
    final todayIndex = now.weekday % 7; // 0=Sun

    // Compute the date for each day slot (Sun=0 .. Sat=6)
    final dates = List.generate(7, (i) {
      final diff = i - todayIndex;
      return now.add(Duration(days: diff));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final isToday = i == todayIndex;
        final isFuture = i > todayIndex;
        final status = weekDays.length > i ? weekDays[i] : DayStatus.none;
        final dayNum = dates[i].day.toString();
        final label = localizedDayShort(l10n, i);

        if (isToday) {
          // Today: white card wrapping label + circle
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: status == DayStatus.done
                        ? Border.all(color: AppColors.orange, width: 2)
                        : Border.all(color: c.separator, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      dayNum,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Build the circle widget based on status
        Widget circle;
        if (status == DayStatus.done) {
          // Past done: solid orange circle
          circle = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.orange, width: 2),
            ),
            child: Center(
              child: Text(
                dayNum,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          );
        } else if (status == DayStatus.frozen) {
          // Frozen: solid blue circle
          circle = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue, width: 2.5),
            ),
            child: Center(
              child: Text(
                dayNum,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          );
        } else if (isFuture) {
          // Future: plain light solid circle
          circle = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.textSecondary.withAlpha(50), width: 2.5),
            ),
            child: Center(
              child: Text(
                dayNum,
                style: TextStyle(
                  fontSize: 16,
                  color: c.textSecondary.withAlpha(100),
                ),
              ),
            ),
          );
        } else {
          // Past not done: dashed circle
          circle = CustomPaint(
            painter: _DashedCirclePainter(
              color: c.textSecondary.withAlpha(120),
              strokeWidth: 2.5,
              dashLength: 4,
              gapLength: 3,
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Center(
                child: Text(
                  dayNum,
                  style: TextStyle(
                    fontSize: 16,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            circle,
          ],
        );
      }),
    );
  }
}

/// Paints a dashed circle border
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * 3.14159265 * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final dashAngle = (dashLength / circumference) * 2 * 3.14159265;
    final totalAngle = 2 * 3.14159265 / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * totalAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}

class _NoAlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: withHaptic(() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AlarmCubit>(),
            child: const AlarmFormScreen(),
          ),
        ),
      )),
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
      onTap: withHaptic(() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AlarmCubit>(),
            child: AlarmFormScreen(alarm: alarm),
          ),
        ),
      )),
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
                  activeThumbColor: c.purpleDeep,
                  onChanged: withHapticValue((val) =>
                      context.read<AlarmCubit>().toggleAlarm(alarm.id, val)),
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
        onTap: withHaptic(onTap),
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

class _AlarmCard extends StatelessWidget {
  final AppAlarmEntry alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final t = alarm.dateTime;
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final isPM = t.hour >= 12;
    final dayStr = alarm.isOneTime ? l10n.alarmsOneTime : _daysLabel(l10n, alarm.repeatDays);

    return GestureDetector(
      onTap: withHaptic(() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<AlarmCubit>(),
            child: AlarmFormScreen(alarm: alarm),
          ),
        ),
      )),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Switch(
                    value: alarm.isEnabled,
                    activeThumbColor: c.purpleDeep,
                    onChanged: withHapticValue((val) =>
                        context.read<AlarmCubit>().toggleAlarm(alarm.id, val)),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  alarm.name.isNotEmpty ? alarm.name : l10n.alarmsDefaultName(1),
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                if (alarm.missions.isNotEmpty) ...[
                  Text(' · ', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                  _StackedMissionIcons(missions: alarm.missions),
                  const SizedBox(width: 6),
                  Text(
                    alarm.missions.length == 1
                        ? localizedMissionName(l10n, alarm.missions.first.type)
                        : l10n.alarmsMissionsCount(alarm.missions.length),
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: withHaptic(() =>
                      context.read<AlarmCubit>().removeAlarm(alarm.id)),
                  child: Icon(Icons.delete_outline,
                      size: 24, color: c.textSecondary.withAlpha(140)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysLabel(AppLocalizations l10n, List<bool> days) {
    if (days.every((d) => d)) return l10n.alarmsEveryDay;
    if (days.every((d) => !d)) return l10n.alarmsOneTime;

    final selected = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) selected.add(localizedDayShort(l10n, i));
    }
    if (days[1] && days[2] && days[3] && days[4] && days[5] &&
        !days[0] && !days[6]) {
      return l10n.alarmsWeekdays;
    }
    return selected.join(', ');
  }
}

/// Stacked/overlapping mission icons
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

class _EmptyAlarmsCard extends StatelessWidget {
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
            Image.asset('assets/siren.png', width: 48, height: 48),
            const SizedBox(height: 12),
            Text(
              l10n.alarmsEmpty,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.alarmsEmptyHint,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

