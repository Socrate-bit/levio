import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../missions/models/mission.dart';

class MorningPlanStep extends StatelessWidget {
  final TimeOfDay alarmTime;
  final MissionType mission;
  final String soundId;
  final List<bool> repeatDays;
  final bool hasSleep;
  final TimeOfDay sleepTime;
  final List<String> relaxingActivities;
  final bool blockApps;

  const MorningPlanStep({
    super.key,
    required this.alarmTime,
    required this.mission,
    required this.soundId,
    required this.repeatDays,
    this.hasSleep = false,
    this.sleepTime = const TimeOfDay(hour: 22, minute: 30),
    this.relaxingActivities = const [],
    this.blockApps = false,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _addMinutes(TimeOfDay t, int mins) {
    final total = (t.hour * 60 + t.minute + mins) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  /// Comma-joined localized wind-down activity names (falls back to the default
  /// routine steps when none were picked).
  String _activitiesLabel(AppLocalizations l10n) {
    final steps =
        relaxingActivities.isNotEmpty ? relaxingActivities : routinePresetSteps;
    return steps.map((a) => localizedItemName(l10n, a)).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final missionName = localizedMissionName(l10n, mission);
    final timeStr = _fmt(alarmTime);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          // Stars placeholder
          Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 22.sp)),
          SizedBox(height: 12.h),
          Text(
            hasSleep
                ? l10n.onboardingSleepPlanTitle
                : l10n.onboardingMorningPlanTitle,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.onboardingMorningPlanSubtitle(timeStr),
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 16.h),
          // Info pills
          Builder(builder: (context) {
            final now = DateTime.now();
            var alarmDt = DateTime(now.year, now.month, now.day,
                alarmTime.hour, alarmTime.minute);
            if (alarmDt.isBefore(now)) {
              alarmDt = alarmDt.add(const Duration(days: 1));
            }
            final diff = alarmDt.difference(now);
            final h = diff.inHours;
            final m = diff.inMinutes % 60;
            final countdown = '${h}h ${m}m';
            final dayLabel = localizedDayShort(l10n, alarmDt.weekday % 7);
            return Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                _Pill(icon: Icons.timer, label: l10n.onboardingStartsIn(countdown), colors: c),
                _Pill(icon: Icons.access_time, label: '$dayLabel, $timeStr', colors: c),
                _Pill(icon: Icons.fitness_center, label: missionName, colors: c),
                _Pill(icon: Icons.notifications, label: localizedSoundName(l10n, soundId), colors: c),
              ],
            );
          }),
          SizedBox(height: 24.h),
          // Timeline
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: c.separator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    hasSleep
                        ? l10n.onboardingSleepRoutineHeader
                        : l10n.onboardingHeresTomorrow,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: const Color(0xFF8E8E93),
                    )),
                SizedBox(height: 16.h),
                // Sleep routine flows chronologically into the morning timeline.
                if (hasSleep) ...[
                  _TimelineItem(
                    icon: Icons.bedtime,
                    label: l10n.onboardingSleepBedtime(_fmt(sleepTime)),
                    colors: c,
                  ),
                  _TimelineLine(colors: c),

                  if (blockApps) ...[
                    _TimelineItem(
                      icon: Icons.phonelink_lock,
                      label: l10n.onboardingSleepBlocked(
                          _fmt(_addMinutes(alarmTime, 20))),
                      colors: c,
                    ),
                    _TimelineLine(colors: c),
                  ],
                ],
                _TimelineItem(
                  icon: Icons.notifications,
                  label: l10n.onboardingAlarmRings(timeStr),
                  colors: c,
                ),
                _TimelineLine(colors: c),
                _TimelineItem(
                  icon: Icons.fitness_center,
                  label: l10n.onboardingCompleteMission(missionName),
                  colors: c,
                ),
                _TimelineLine(colors: c),
                _TimelineItem(
                  icon: Icons.check_circle,
                  label: l10n.onboardingYoureUp,
                  colors: c,
                  isLast: true,
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.onboardingNoSnooze,
                  style: TextStyle(
                      fontSize: 14.sp, color: c.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          SizedBox(height: 40.h),
          // App icon
          ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Image.asset(
              'assets/icon.png',
              width: 120.w,
              height: 120.h,
            ),
          ),
          SizedBox(height: 32.h),
          // Rise and repeat
          Text(
            l10n.onboardingRiseAndRepeat,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.onboardingAlarmFrequency(repeatDays.where((d) => d).length),
            style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
          ),
          SizedBox(height: 16.h),
          // Day circles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) =>
              _DayCircle(localizedDayShort(l10n, i)[0], repeatDays[i], c),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _Pill({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.separator),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: colors.textSecondary),
          SizedBox(width: 6.w),
          Text(label,
              style:
                  TextStyle(fontSize: 13.sp, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.colors,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: colors.separator,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18.sp, color: colors.textPrimary),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  final AppColors colors;
  const _TimelineLine({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 17.w),
      child: Container(
        width: 2,
        height: 24.h,
        color: colors.separator,
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String letter;
  final bool isActive;
  final AppColors colors;

  const _DayCircle(this.letter, this.isActive, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppColors.orange : Colors.transparent,
          border: isActive
              ? null
              : Border.all(color: colors.textSecondary, width: 1),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
