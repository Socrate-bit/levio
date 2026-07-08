import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../alarms/screens/alarm_form_screen.dart';
import '../../alarms/services/alarm_readiness_guard.dart';
import '../../alarms/widgets/alarm_kind_icon.dart';
import '../../dismiss/screens/mission_sequence_screen.dart';
import '../../insights/widgets/hexagon_badge.dart';
import '../../milestones/models/badge_model.dart';
import '../../milestones/screens/milestones_screen.dart';
import '../../milestones/screens/streak_screen.dart';
import '../../missions/models/mission.dart';
import '../../missions/widgets/stacked_mission_icons.dart';
import '../../screentime/cubit/screentime_cubit.dart';
import '../../screentime/cubit/screentime_state.dart';
import '../../wakeup/services/history_service.dart';
import '../../screentime/screens/screentime_detail_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/bottom_nav_shell.dart';
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
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            bottom: false,
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        const _TopBar(),
                        SizedBox(height: 18.h),
                        _MotivationCard(state: state),
                        SizedBox(height: 16.h),
                        BlocBuilder<AlarmCubit, AlarmState>(
                          builder: (context, alarmState) {
                            final now = DateTime.now();
                            // Enabled alarms with a real upcoming fire time.
                            final upcoming =
                                alarmState.alarms
                                    .where((a) => a.isEnabled)
                                    .map(
                                      (a) =>
                                          (alarm: a, fireAt: a.nextFireAt(now)),
                                    )
                                    .where((e) => e.fireAt != null)
                                    .toList()
                                  ..sort(
                                    (a, b) => a.fireAt!.compareTo(b.fireAt!),
                                  );

                            final next = upcoming.isNotEmpty
                                ? upcoming.first.alarm
                                : null;
                            // Soonest wake-up and soonest sleep alarm for the
                            // bedtime → wake-up ring.
                            final wakeAlarm = upcoming
                                .where((e) => !e.alarm.isSleep)
                                .map((e) => e.alarm)
                                .firstOrNull;
                            final sleepAlarm = upcoming
                                .where((e) => e.alarm.isSleep)
                                .map((e) => e.alarm)
                                .firstOrNull;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (next != null)
                                  _NextAlarmCard(
                                    alarm: next,
                                    completedToday: state.completedAlarmIdsToday
                                        .contains(next.id),
                                  )
                                else
                                  const _NoAlarmCard(),
                                SizedBox(height: 16.h),
                                _SleepScheduleCard(
                                  sleepAlarm: sleepAlarm,
                                  wakeAlarm: wakeAlarm,
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                        const _ScreenBlockerCard(),
                        SizedBox(height: 120.h),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Image.asset('assets/icon.png', width: 42.w, height: 42.h),
        SizedBox(width: 8.w),
        Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        // Settings now lives in the top bar (no longer a bottom-nav tab).
        GestureDetector(
          onTap: withHaptic(
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8),
              ],
            ),
            child: Icon(
              Icons.settings_rounded,
              size: 24.sp,
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Motivation card (streak / best / badge / week / next-badge progress)
// ---------------------------------------------------------------------------

class _MotivationCard extends StatelessWidget {
  final HomeState state;
  const _MotivationCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warm surface + on-surface colors that read well on the cream card.
    final cardColor = isDark ? const Color.fromARGB(29, 255, 128, 0) : AppColors.orangeLight;
    final primary = isDark ? c.textPrimary : const Color(0xFF3D2E1E);
    final secondary = isDark ? c.textSecondary : const Color(0xFF9B7B4B);

    final badges = buildStreakBadges();
    // Highest-value streak badge the user has already earned.
    BadgeModel? latest;
    for (final b in badges) {
      if (state.earnedBadgeIds.contains(b.id)) latest = b;
    }
    // First streak badge still ahead of the current streak.
    BadgeModel? next;
    for (final b in badges) {
      if ((b.requiredDays ?? 0) > state.currentStreak) {
        next = b;
        break;
      }
    }
    final progress = next != null
        ? (state.currentStreak / next.requiredDays!).clamp(0.0, 1.0)
        : 1.0;
    // Show the actual streak badge: the highest one earned, otherwise the next
    // goal rendered greyed-out.
    final displayBadge = latest ?? (badges.isNotEmpty ? badges.first : null);

    return GestureDetector(
      onTap: withHaptic(() => BottomNavShell.of(context)?.navigateTo(2)),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: withHaptic(() => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StreakScreen()),
                      )),
                  child: Row(
                    children: [
                      Image.asset('assets/streaks.png',
                          width: 50.w, height: 50.h),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.currentStreak}',
                            style: TextStyle(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.bold,
                              color: primary,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            l10n.homeCurrentStreak,
                            style: TextStyle(fontSize: 13.sp, color: secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (displayBadge != null)
                  HexagonBadge(
                    label: displayBadge.displayValue,
                    earned: latest != null,
                    earnedColor: AppColors.orange,
                    size: 70.w,
                    imageAsset: displayBadge.imageAsset,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MilestonesScreen()),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 16.h),
            if (next != null) ...[
              Row(
                children: [
                  Text(
                    l10n.homeNextBadge(next.requiredDays!),
                    style: TextStyle(fontSize: 13.sp, color: secondary),
                  ),
                  const Spacer(),
                  Text(
                    '${state.currentStreak} / ${next.requiredDays}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.h,
                  backgroundColor: AppColors.orange.withAlpha(40),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.orange,
                  ),
                ),
              ),
            ] else
              Text(
                l10n.homeAllBadgesEarned,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            SizedBox(height: 16.h),
            _WeekRow(weekDays: state.weekDays),
          ],
        ),
      ),
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

        Widget circle;
        if (status == DayStatus.done) {
          circle = _circle(
            child: Icon(
              Icons.check_rounded,
              size: 26.sp,
              color: AppColors.orange,
            ),
            border: AppColors.orange,
          );
        } else if (status == DayStatus.frozen) {
          circle = _circle(
            child: Icon(Icons.ac_unit, size: 22.sp, color: AppColors.blue),
            border: AppColors.blue,
          );
        } else if (status == DayStatus.missed) {
          circle = _circle(
            child: Icon(
              Icons.close_rounded,
              size: 26.sp,
              color: AppColors.error,
            ),
            border: AppColors.error,
          );
        } else if (isFuture) {
          circle = _circle(
            child: Text(
              dayNum,
              style: TextStyle(
                fontSize: 15.sp,
                color: c.textSecondary.withAlpha(110),
              ),
            ),
            border: c.textSecondary.withAlpha(50),
            width: 2.5,
          );
        } else {
          circle = CustomPaint(
            painter: _DashedCirclePainter(
              color: c.textSecondary.withAlpha(120),
              strokeWidth: 2.5,
              dashLength: 4,
              gapLength: 3,
            ),
            child: SizedBox(
              width: 38.w,
              height: 38.w,
              child: Center(
                child: Text(
                  dayNum,
                  style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
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
                fontSize: 12.sp,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? c.textPrimary : c.textSecondary,
              ),
            ),
            SizedBox(height: 6.h),
            circle,
          ],
        );
      }),
    );
  }

  Widget _circle({
    required Widget child,
    required Color border,
    double width = 3,
  }) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: width),
      ),
      child: Center(child: child),
    );
  }
}

/// Paints a dashed circle border.
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
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final dashAngle = (dashLength / circumference) * 2 * math.pi;
    final totalAngle = 2 * math.pi / dashCount;

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
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

// ---------------------------------------------------------------------------
// Next alarm / mission card
// ---------------------------------------------------------------------------

class _NoAlarmCard extends StatelessWidget {
  const _NoAlarmCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: withHaptic(() async {
        if (!await AlarmReadinessGuard.check(context)) return;
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AlarmCubit>(),
              child: const AlarmFormScreen(),
            ),
          ),
        );
      }),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
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
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.all(9.w),
              child: Image.asset('assets/siren.png'),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeNoActiveAlarm,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    l10n.homeNoActiveAlarmHint,
                    style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textSecondary, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

class _NextAlarmCard extends StatefulWidget {
  final AppAlarmEntry alarm;
  // True when this alarm's mission was already completed today, so today's fire
  // is consumed: "Start now" is hidden and the countdown reflects the next day.
  final bool completedToday;
  const _NextAlarmCard({required this.alarm, this.completedToday = false});

  @override
  State<_NextAlarmCard> createState() => _NextAlarmCardState();
}

class _NextAlarmCardState extends State<_NextAlarmCard> {
  /// Runs the alarm's mission early (before it rings). Creates a pending session
  /// so the completion is recorded, then launches the full mission flow in
  /// [MissionSequenceScreen] with `earlyStart`, which consumes today's occurrence
  /// on completion so the alarm won't also ring today.
  Future<void> _startNow() async {
    final alarm = widget.alarm;
    if (alarm.missions.isEmpty) return;
    final alarmCubit = context.read<AlarmCubit>();
    await HistoryService.createPendingSession(
      alarmId: alarm.id,
      missionType: alarm.missions.first.type,
      soundId: alarm.soundId,
      isSleep: alarm.isSleep,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: alarmCubit,
          child: MissionSequenceScreen(
            missions: alarm.missions,
            alarmId: alarm.id,
            nativeAlarmId: alarm.id,
            alarmLabel: alarm.name,
            isSleep: alarm.isSleep,
            earlyStart: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final alarm = widget.alarm;
    final now = DateTime.now();
    // Once today's mission is done, treat the rest of today as elapsed so the
    // countdown points at the next day's fire instead of the consumed one.
    final reference = widget.completedToday
        ? DateTime(now.year, now.month, now.day, 23, 59, 59)
        : now;
    final fireAt = alarm.nextFireAt(reference) ?? alarm.dateTime;
    final diff = fireAt.difference(now);
    // Offer "Start now" when the next fire is within 90 min, the alarm is on, it
    // has a mission to run, and today's occurrence hasn't already been completed.
    final canStartNow =
        alarm.isEnabled &&
        !widget.completedToday &&
        !diff.isNegative &&
        diff.inMinutes <= 90 &&
        alarm.missions.isNotEmpty;
    final hoursLeft = diff.inHours;
    final minsLeft = diff.inMinutes % 60;
    final timeStr = _formatTime(alarm.dateTime);
    final isPM = alarm.dateTime.hour >= 12;
    final missionLabel = alarm.missions.length > 1
        ? l10n.alarmsMissionsCount(alarm.missions.length)
        : localizedMissionName(
            l10n,
            alarm.missions.isNotEmpty
                ? alarm.missions.first.type
                : MissionType.none,
          );
    final dayLabel = diff.isNegative || diff.inHours < 24
        ? l10n.homeToday
        : l10n.homeTomorrow;

    return GestureDetector(
      onTap: withHaptic(
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AlarmCubit>(),
              child: AlarmFormScreen(alarm: alarm),
            ),
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
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
            Row(
              children: [
                AlarmKindIcon(isSleep: alarm.isSleep, size: 32.sp),
                SizedBox(width: 8.w),
                Text(
                  dayLabel,
                  style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: 4.w),
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Text(
                    isPM ? 'pm' : 'am',
                    style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: alarm.isEnabled,
                  activeThumbColor: c.purpleDeep,
                  onChanged: withHapticValue((val) async {
                    if (val && !await AlarmReadinessGuard.check(context))
                      return;
                    if (!context.mounted) return;
                    context.read<AlarmCubit>().toggleAlarm(alarm.id, val);
                  }),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 14.sp,
                  color: c.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  diff.isNegative
                      ? l10n.homePastAlarm
                      : l10n.homeRingsIn(hoursLeft, minsLeft),
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // Alarm name + stacked mission icons, mirroring the alarm-list card.
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          alarm.name.isNotEmpty
                              ? alarm.name
                              : l10n.alarmsDefaultName(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      if (alarm.missions.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: c.textSecondary,
                          ),
                        ),
                        StackedMissionIcons(missions: alarm.missions),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            missionLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canStartNow) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: withHaptic(_startNow),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: c.textPrimary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 20.sp,
                            color: c.background,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            l10n.homeStartNow,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: c.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

// ---------------------------------------------------------------------------
// Sleep-schedule ring card
// ---------------------------------------------------------------------------

class _SleepScheduleCard extends StatelessWidget {
  final AppAlarmEntry? sleepAlarm;
  final AppAlarmEntry? wakeAlarm;
  const _SleepScheduleCard({required this.sleepAlarm, required this.wakeAlarm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final bothSet = sleepAlarm != null && wakeAlarm != null;

    int? bedMin;
    int? wakeMin;
    int inBedH = 0;
    int inBedM = 0;
    if (bothSet) {
      bedMin = sleepAlarm!.dateTime.hour * 60 + sleepAlarm!.dateTime.minute;
      wakeMin = wakeAlarm!.dateTime.hour * 60 + wakeAlarm!.dateTime.minute;
      var inBed = wakeMin - bedMin;
      if (inBed <= 0) inBed += 24 * 60;
      inBedH = inBed ~/ 60;
      inBedM = inBed % 60;
    }

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130.w,
            height: 130.w,
            child: CustomPaint(
              // A grey track always renders; the coloured arc only appears once
              // both a bedtime and a wake-up alarm are set.
              painter: _SleepRingPainter(
                bedMinutes: bedMin,
                wakeMinutes: wakeMin,
                trackColor: c.textSecondary.withAlpha(45),
                arcColor: c.purpleDeep,
                dotColor: AppColors.orangeLight,
              ),
              child: Center(
                child: bothSet
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${inBedH}h ${inBedM}m',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            l10n.homeInBed,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.bedtime_outlined,
                        size: 30.sp,
                        color: c.textSecondary.withAlpha(120),
                      ),
              ),
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sleepAlarm != null)
                  _SleepInfoRow(
                    icon: Icons.nightlight_round,
                    color: AppColors.of(context).purpleDeep,
                    label: l10n.homeBedtime,
                    time: _fmt(sleepAlarm!.dateTime),
                    onTap: () => _openAlarm(context, sleepAlarm!),
                  )
                else
                  const _SetupCta(isSleep: true),
                SizedBox(height: 16.h),
                if (wakeAlarm != null)
                  _SleepInfoRow(
                    icon: Icons.notifications_active_rounded,
                    color: AppColors.orange,
                    label: l10n.homeWakeUp,
                    time: _fmt(wakeAlarm!.dateTime),
                    onTap: () => _openAlarm(context, wakeAlarm!),
                  )
                else
                  const _SetupCta(isSleep: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAlarm(BuildContext context, AppAlarmEntry alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AlarmCubit>(),
          child: AlarmFormScreen(alarm: alarm),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}

class _SleepInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String time;
  final VoidCallback? onTap;
  const _SleepInfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupCta extends StatelessWidget {
  final bool isSleep;
  const _SetupCta({required this.isSleep});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: withHaptic(() async {
        if (!await AlarmReadinessGuard.check(context)) return;
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AlarmCubit>(),
              child: AlarmFormScreen(initialIsSleep: isSleep),
            ),
          ),
        );
      }),
      child: Row(
        children: [
          AlarmKindIcon(isSleep: isSleep, size: 40),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              isSleep ? l10n.homeSetBedtime : l10n.homeSetWakeUp,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: c.textSecondary, size: 20.sp),
        ],
      ),
    );
  }
}

/// Draws the "time in bed" ring: a full track plus a coloured arc spanning the
/// bedtime → wake-up window on a 24h clock, with a dot at each endpoint.
class _SleepRingPainter extends CustomPainter {
  final int? bedMinutes;
  final int? wakeMinutes;
  final Color trackColor;
  final Color arcColor;
  final Color dotColor;

  _SleepRingPainter({
    required this.bedMinutes,
    required this.wakeMinutes,
    required this.trackColor,
    required this.arcColor,
    required this.dotColor,
  });

  // Angle (radians) for a minute-of-day, with midnight at the top (12 o'clock).
  double _angle(int minutes) => -math.pi / 2 + (minutes / 1440) * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final radius = (size.width - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    // Only draw the coloured window when both endpoints exist.
    if (bedMinutes == null || wakeMinutes == null) return;

    final start = _angle(bedMinutes!);
    var sweepMin = wakeMinutes! - bedMinutes!;
    if (sweepMin <= 0) sweepMin += 1440;
    final sweep = (sweepMin / 1440) * 2 * math.pi;

    final arc = Paint()
      ..color = arcColor
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, start, sweep, false, arc);

    // Endpoint dots.
    final dot = Paint()..color = dotColor;
    final dotBorder = Paint()
      ..color = arcColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final a in [start, start + sweep]) {
      final p = Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      );
      canvas.drawCircle(p, stroke / 1.6, dot);
      canvas.drawCircle(p, stroke / 1.6, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepRingPainter old) =>
      old.bedMinutes != bedMinutes ||
      old.wakeMinutes != wakeMinutes ||
      old.trackColor != trackColor ||
      old.arcColor != arcColor ||
      old.dotColor != dotColor;
}

// ---------------------------------------------------------------------------
// Screen-blocker card
// ---------------------------------------------------------------------------

class _ScreenBlockerCard extends StatelessWidget {
  const _ScreenBlockerCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ScreenTimeCubit, ScreenTimeState>(
      builder: (context, state) {
        final active = state.isActiveNow;

        String status;
        if (active && state.activeUntil != null) {
          final until = TimeOfDay.fromDateTime(
            state.activeUntil!,
          ).format(context);
          status = l10n.homeBlockerActiveUntil(until);
        } else if (state.enabled && state.activeIn != null) {
          final d = state.activeIn!;
          status = l10n.homeBlockerActiveIn(d.inHours, d.inMinutes % 60);
        } else {
          status = l10n.homeBlockerOff;
        }

        final cardColor = active
            ? AppColors.of(context).purpleDeep.withAlpha(isDark ? 45 : 30)
            : c.card;

        void openDetail() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<ScreenTimeCubit>(),
                child: const ScreenTimeDetailScreen(),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: withHaptic(openDetail),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: active
                  ? Border.all(
                      color: AppColors.of(context).purpleDeep.withAlpha(80),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  active ? Icons.shield : Icons.shield_outlined,
                  size: 26.sp,
                  color: active
                      ? AppColors.of(context).purpleDeep
                      : c.textSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeScreenBlocker,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: active
                              ? AppColors.of(context).purpleDeep
                              : c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: withHaptic(openDetail),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.of(context).purpleDeep.withAlpha(45)
                          : c.background,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeManage,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.of(context).purpleDeep
                                : c.textPrimary,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.chevron_right,
                          size: 18.sp,
                          color: active
                              ? AppColors.of(context).purpleDeep
                              : c.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
