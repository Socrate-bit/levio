import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../missions/models/mission.dart';

class MorningPlanStep extends StatelessWidget {
  final TimeOfDay alarmTime;
  final MissionType mission;
  final String soundId;
  final List<bool> repeatDays;

  const MorningPlanStep({
    super.key,
    required this.alarmTime,
    required this.mission,
    required this.soundId,
    required this.repeatDays,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final missionName = localizedMissionName(l10n, mission);
    final timeStr = _fmt(alarmTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Stars placeholder
          const Text('🏅⭐⭐⭐⭐⭐🏅', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingMorningPlanTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingMorningPlanSubtitle(timeStr),
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
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
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _Pill(icon: Icons.timer, label: l10n.onboardingStartsIn(countdown), colors: c),
                _Pill(icon: Icons.access_time, label: '$dayLabel, $timeStr', colors: c),
                _Pill(icon: Icons.fitness_center, label: missionName, colors: c),
                _Pill(icon: Icons.notifications, label: localizedSoundName(l10n, soundId), colors: c),
              ],
            );
          }),
          const SizedBox(height: 24),
          // Timeline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.separator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.onboardingHeresTomorrow,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Color(0xFF8E8E93),
                    )),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                Text(
                  l10n.onboardingNoSnooze,
                  style: TextStyle(
                      fontSize: 14, color: c.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Wake receipt placeholder
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: c.separator,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                l10n.onboardingWakeReceipt,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Rise and repeat
          Text(
            l10n.onboardingRiseAndRepeat,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAlarmFrequency(repeatDays.where((d) => d).length),
            style: TextStyle(fontSize: 15, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          // Day circles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) =>
              _DayCircle(localizedDayShort(l10n, i)[0], repeatDays[i], c),
            ),
          ),
          const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.separator),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: colors.textPrimary)),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.separator,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: colors.textPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
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
      padding: const EdgeInsets.only(left: 17),
      child: Container(
        width: 2,
        height: 24,
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 36,
        height: 36,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
