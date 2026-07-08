import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
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

  // Optional edit hooks (v2). When provided, the matching plan row becomes
  // tappable and shows an edit affordance. Left null in v1 → read-only.
  final VoidCallback? onEditTime;
  final VoidCallback? onEditMission;
  final VoidCallback? onEditSound;
  final VoidCallback? onEditDays;
  final VoidCallback? onEditSleepTime;
  final VoidCallback? onEditWakeRoutine;
  final VoidCallback? onEditNightRoutine;

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
    this.onEditTime,
    this.onEditMission,
    this.onEditSound,
    this.onEditDays,
    this.onEditSleepTime,
    this.onEditWakeRoutine,
    this.onEditNightRoutine,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _addMinutes(TimeOfDay t, int mins) {
    final total = (t.hour * 60 + t.minute + mins) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
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
                    onTap: onEditSleepTime,
                  ),
                  _TimelineLine(colors: c),
                  if (onEditNightRoutine != null) ...[
                    _TimelineItem(
                      icon: Icons.self_improvement,
                      label: l10n.onboardingV2NightRoutineRow,
                      colors: c,
                      onTap: onEditNightRoutine,
                    ),
                    _TimelineLine(colors: c),
                  ],

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
                  onTap: onEditTime,
                ),
                _TimelineLine(colors: c),
                _TimelineItem(
                  icon: Icons.fitness_center,
                  label: l10n.onboardingCompleteMission(missionName),
                  colors: c,
                  onTap: onEditMission,
                ),
                _TimelineLine(colors: c),
                if (onEditWakeRoutine != null) ...[
                  _TimelineItem(
                    icon: Icons.checklist,
                    label: l10n.onboardingV2WakeRoutineRow,
                    colors: c,
                    onTap: onEditWakeRoutine,
                  ),
                  _TimelineLine(colors: c),
                ],
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
          Text(
            l10n.onboardingAlarmFrequency(repeatDays.where((d) => d).length),
            style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
          ),
          SizedBox(height: 16.h),
          // Day circles
          GestureDetector(
            onTap: onEditDays,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) =>
                _DayCircle(localizedDayShort(l10n, i)[0], repeatDays[i], c),
              ),
            ),
          ),
          SizedBox(height: 32.h),
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
  final VoidCallback? onTap;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.colors,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : withHaptic(onTap!),
      child: Row(
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
          if (onTap != null)
            Icon(Icons.edit, size: 14.sp, color: colors.textPrimary),
        ],
      ),
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
          color: isActive ? colors.textPrimary : Colors.transparent,
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
              color: isActive ? colors.background : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
