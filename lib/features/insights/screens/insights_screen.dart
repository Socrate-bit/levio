import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/hexagon_badge.dart';
import '../../milestones/screens/milestones_screen.dart';
import '../../missions/models/mission.dart';
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
                : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.insightsTitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RangeToggle(
                            selected: state.range,
                            onChanged: (r) =>
                                ctx.read<InsightsCubit>().changeRange(r),
                          ),
                          const SizedBox(height: 20),
                          // Streak + Badges cards row
                          Row(
                            children: [
                              Expanded(
                                child: _StreakCard(
                                  streak: state.currentStreak,
                                  onTap: () => Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MilestonesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _BadgesCard(
                                  earned: state.badgesEarned,
                                  total: state.totalBadges,
                                  onTap: () => Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MilestonesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            l10n.insightsStats,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatCard(
                                icon: Icons.access_time_outlined,
                                label: l10n.insightsAvgWakeTime,
                                value: state.avgWakeTime,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                icon: Icons.timer_outlined,
                                label: l10n.insightsAvgResponse,
                                value: state.avgResponseTime,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatCard(
                                icon: Icons.fitness_center_outlined,
                                label: l10n.insightsFavoriteMission,
                                value: state.favoriteMission == '--'
                                    ? '--'
                                    : localizedMissionName(l10n, MissionType.values.byName(state.favoriteMission)),
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                icon: Icons.music_note_outlined,
                                label: l10n.insightsFavoriteSound,
                                value: state.favoriteSound == '--'
                                    ? '--'
                                    : localizedSoundName(l10n, state.favoriteSound),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // History section
                          Text(
                            l10n.sessionsTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (state.sessions.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  l10n.sessionsNoWakeups,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...state.sessions.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
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
        );
      },
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: InsightsRange.values.map((r) {
          final isSelected = selected == r;
          return Expanded(
            child: GestureDetector(
              onTap: withHaptic(() => onChanged(r)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[r]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/streaks.png', width: 56, height: 56),
              const SizedBox(height: 4),
              Text(
                '$streak',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                l10n.insightsDayStreak,
                style: TextStyle(
                  fontSize: 13,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HexagonBadge(
                label: '$earned',
                earned: earned > 0,
                size: 64,
                earnedColor: const Color(0xFFB8860B),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.insightsBadgesEarned,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              if (earned > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$earned/$total',
                    style: TextStyle(
                      fontSize: 12,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: c.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final double score;
  const _ConsistencyCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.insightsConsistency,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: withHaptic(() => _showInfo(context)),
                child: Icon(Icons.help_outline,
                    size: 18, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (score < 30)
            Text(
              l10n.insightsNeed3Wakeups,
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
          const SizedBox(height: 12),
          // Multi-color progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Background gradient
                  const Row(
                    children: [
                      Expanded(
                        flex: 30,
                        child: ColoredBox(color: Color(0xFFFC8181)),
                      ),
                      Expanded(
                        flex: 20,
                        child: ColoredBox(color: Color(0xFFED8936)),
                      ),
                      Expanded(
                        flex: 20,
                        child: ColoredBox(color: Color(0xFF4299E1)),
                      ),
                      Expanded(
                        flex: 30,
                        child: ColoredBox(color: Color(0xFF48BB78)),
                      ),
                    ],
                  ),
                  // Dark overlay to show "unfilled" portion
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: (1 - score / 100) *
                        (MediaQuery.of(context).size.width - 72),
                    child: Container(
                      color: c.card.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style: TextStyle(
                      fontSize: 11, color: c.textSecondary)),
              Text('30',
                  style: TextStyle(
                      fontSize: 11, color: c.textSecondary)),
              Text('50',
                  style: TextStyle(
                      fontSize: 11, color: c.textSecondary)),
              Text('70',
                  style: TextStyle(
                      fontSize: 11, color: c.textSecondary)),
              Text('100',
                  style: TextStyle(
                      fontSize: 11, color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _LegendDot(color: const Color(0xFFFC8181), label: l10n.insightsConsistencyVariable),
              _LegendDot(color: const Color(0xFFED8936), label: l10n.insightsConsistencyImproving),
              _LegendDot(color: const Color(0xFF4299E1), label: l10n.insightsConsistencyRegular),
              _LegendDot(color: const Color(0xFF48BB78), label: l10n.insightsConsistencyConsistent),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.insightsConsistencyScoreTitle),
        content: Text(l10n.insightsConsistencyScoreBody),
        actions: [
          TextButton(
            onPressed: withHaptic(() => Navigator.pop(context)),
            child: Text(l10n.insightsOk),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: c.textSecondary)),
      ],
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
    final missionIcon = session.missionType != null
        ? missionInfoFor(session.missionType!).icon
        : Icons.wb_sunny;
    final missionColor = session.missionType != null
        ? missionInfoFor(session.missionType!).iconColor
        : AppColors.orange;

    final mins = session.timeTakenSeconds ~/ 60;
    final secs = session.timeTakenSeconds % 60;
    final durationStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    final missed = !session.completed;
    final iconColor = missed ? c.textSecondary : missionColor;
    final iconBg = missed
        ? c.textSecondary.withAlpha(20)
        : missionColor.withAlpha(25);

    return Opacity(
      opacity: missed ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                missed ? Icons.alarm_off_outlined : missionIcon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    missed ? l10n.sessionsMissed : missionLabel,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 13, color: c.textSecondary),
                ),
                const SizedBox(height: 2),
                if (!missed)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12, color: c.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        durationStr,
                        style:
                            TextStyle(fontSize: 12, color: c.textSecondary),
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
