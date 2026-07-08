import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../../shared/theme/app_theme.dart';
import '../widgets/hexagon_badge.dart';
import '../widgets/next_badge_card.dart';
import '../widgets/streak_heatmap.dart';
import '../widgets/success_progression_chart.dart';
import '../../milestones/screens/milestones_screen.dart';
import '../../missions/models/mission.dart';
import '../../missions/widgets/mission_icon.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../cubit/insights_cubit.dart';
import '../cubit/insights_state.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => InsightsCubit(),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  void _openMilestones(BuildContext ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const MilestonesScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (ctx, state) {
        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            bottom: false,
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ctx.read<InsightsCubit>().load(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 120.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.insightsTitle,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          _RangeToggle(
                            selected: state.range,
                            onChanged: (r) =>
                                ctx.read<InsightsCubit>().changeRange(r),
                          ),

                          // ── Milestones ──────────────────────────────────
                          SizedBox(height: 20.h),
                          _SectionTitle(l10n.insightsMilestones),
                          SizedBox(height: 12.h),
                          NextBadgeCard(
                            currentBadge: state.currentBadge,
                            nextBadge: state.nextBadge,
                            currentStreak: state.currentStreak,
                            onTap: () => _openMilestones(ctx),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(
                                child: _StreakCard(
                                  streak: state.currentStreak,
                                  onTap: () => _openMilestones(ctx),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _BadgesCard(
                                  earned: state.badgesEarned,
                                  total: state.totalBadges,
                                  onTap: () => _openMilestones(ctx),
                                ),
                              ),
                            ],
                          ),

                          // ── Streak ──────────────────────────────────────
                          SizedBox(height: 22.h),
                          _SectionTitle(l10n.insightsStreakSection),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              _StatCard(
                                icon: Icons.local_fire_department_outlined,
                                label: l10n.insightsBestStreak,
                                value: '${state.longestStreak}',
                              ),
                              SizedBox(width: 12.w),
                              _StatCard(
                                icon: Icons.check_circle_outline,
                                label: l10n.insightsSuccesses,
                                value: '${state.successCount}',
                              ),
                              SizedBox(width: 12.w),
                              _StatCard(
                                icon: Icons.percent_outlined,
                                label: l10n.insightsSuccessRate,
                                value: '${state.successRate.round()}%',
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          StreakHeatmap(days: state.heatmap),

                          // ── Success over time ───────────────────────────
                          SizedBox(height: 22.h),
                          _SectionTitle(l10n.insightsSuccessSection),
                          SizedBox(height: 12.h),
                          SuccessProgressionChart(
                            points: state.progression,
                            range: state.range,
                          ),

                          // ── Timing ──────────────────────────────────────
                          SizedBox(height: 22.h),
                          _SectionTitle(l10n.insightsTiming),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              _StatCard(
                                icon: Icons.wb_sunny_outlined,
                                label: l10n.insightsAvgWakeTime,
                                value: state.avgWakeTime,
                              ),
                              SizedBox(width: 12.w),
                              _StatCard(
                                icon: Icons.nightlight_outlined,
                                label: l10n.insightsAvgSleepTime,
                                value: state.avgSleepTime,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              _StatCard(
                                icon: Icons.timer_outlined,
                                label: l10n.insightsAvgWakeRoutine,
                                value: state.avgWakeRoutine,
                              ),
                              SizedBox(width: 12.w),
                              _StatCard(
                                icon: Icons.bedtime_outlined,
                                label: l10n.insightsAvgSleepRoutine,
                                value: state.avgSleepRoutine,
                              ),
                            ],
                          ),

                          // ── Preferences ─────────────────────────────────
                          SizedBox(height: 22.h),
                          _SectionTitle(l10n.insightsPreferences),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              _StatCard(
                                icon: Icons.fitness_center_outlined,
                                label: l10n.insightsFavoriteMission,
                                value: state.favoriteMission == '--'
                                    ? '--'
                                    : localizedMissionName(l10n,
                                        MissionType.values
                                            .byName(state.favoriteMission)),
                              ),
                              SizedBox(width: 12.w),
                              _StatCard(
                                icon: Icons.music_note_outlined,
                                label: l10n.insightsFavoriteSound,
                                value: state.favoriteSound == '--'
                                    ? '--'
                                    : localizedSoundName(
                                        l10n, state.favoriteSound),
                              ),
                            ],
                          ),

                          // ── Sessions ────────────────────────────────────
                          SizedBox(height: 24.h),
                          _SectionTitle(l10n.sessionsTitle),
                          SizedBox(height: 12.h),
                          if (state.sessions.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.h),
                                child: Text(
                                  l10n.sessionsNoWakeups,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...state.sessions.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(bottom: 10.h),
                                    child: _SessionTile(
                                      session: entry.value,
                                      wakeupNumber:
                                          state.totalWakeups - entry.key,
                                    ),
                                  ),
                                ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final InsightsRange selected;
  final ValueChanged<InsightsRange> onChanged;

  const _RangeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = {
      InsightsRange.week: l10n.insightsWeek,
      InsightsRange.month: l10n.insightsMonth,
      InsightsRange.allTime: l10n.insightsAllTime,
    };
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: InsightsRange.values.map((r) {
          final isSelected = selected == r;
          return Expanded(
            child: GestureDetector(
              onTap: withHaptic(() => onChanged(r)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.of(context).textPrimary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  labels[r]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : c.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;

  const _StreakCard({
    required this.streak,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/streaks.png', width: 56.w, height: 56.h),
              SizedBox(height: 4.h),
              Text(
                '$streak',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                l10n.insightsDayStreak,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgesCard extends StatelessWidget {
  final int earned;
  final int total;
  final VoidCallback onTap;

  const _BadgesCard({
    required this.earned,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HexagonBadge(
                label: '$earned',
                earned: earned > 0,
                size: 64.w,
                earnedColor: const Color(0xFFB8860B),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.insightsBadgesEarned,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              if (earned > 0)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    '$earned/$total',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: c.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13.sp, color: c.textSecondary),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WakeupSession session;
  final int wakeupNumber;

  const _SessionTile({
    required this.session,
    required this.wakeupNumber,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final ts = session.timestamp;
    final h = ts.hour > 12 ? ts.hour - 12 : (ts.hour == 0 ? 12 : ts.hour);
    final isPM = ts.hour >= 12;
    final timeStr =
        '$h:${ts.minute.toString().padLeft(2, '0')} ${isPM ? 'pm' : 'am'}';
    final dateStr = '${localizedMonth(l10n, ts.month)} ${ts.day}';
    final missionLabel = session.missionType != null
        ? localizedMissionName(l10n, session.missionType!)
        : l10n.wakeupWakeUp;
    final missionColor = session.missionType != null
        ? missionInfoFor(session.missionType!).iconColor
        : AppColors.orange;

    final mins = session.timeTakenSeconds ~/ 60;
    final secs = session.timeTakenSeconds % 60;
    final durationStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    final disabled = session.screenTimeDisabled;
    final incomplete = !session.completed; // disabled or a real missed alarm
    final missed = incomplete && !disabled; // a real missed alarm only

    // Screen-time-disabled entries get their own look (distinct icon/color, full
    // opacity) so they don't read as a missed alarm. Real missed alarms stay
    // muted and dimmed.
    final Color iconColor;
    final Color iconBg;
    final IconData statusIcon;
    final String statusLabel;
    if (disabled) {
      iconColor = AppColors.error;
      iconBg = AppColors.error.withAlpha(25);
      statusIcon = Icons.app_blocking;
      statusLabel = l10n.sessionsScreenTimeDisabled;
    } else if (missed) {
      iconColor = c.textSecondary;
      iconBg = c.textSecondary.withAlpha(20);
      statusIcon = Icons.alarm_off_outlined;
      statusLabel = l10n.sessionsMissed;
    } else {
      iconColor = missionColor;
      iconBg = missionColor.withAlpha(25);
      statusIcon = Icons.wb_sunny;
      statusLabel = missionLabel;
    }

    return Opacity(
      opacity: missed ? 0.6 : 1.0,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: incomplete
                    ? Icon(statusIcon, color: iconColor, size: 22.sp)
                    : session.missionType != null
                        ? MissionIcon(
                            info: missionInfoFor(session.missionType!),
                            size: 28.sp,
                          )
                        : Icon(Icons.wb_sunny, color: iconColor, size: 22.sp),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    incomplete ? statusLabel : missionLabel,
                    style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
                SizedBox(height: 2.h),
                if (!incomplete)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12.sp, color: c.textSecondary),
                      SizedBox(width: 3.w),
                      Text(
                        durationStr,
                        style:
                            TextStyle(fontSize: 12.sp, color: c.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
