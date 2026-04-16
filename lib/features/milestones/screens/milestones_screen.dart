import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../shared/widgets/hexagon_badge.dart';
import '../cubit/milestones_cubit.dart';
import '../cubit/milestones_state.dart';
import '../models/badge_model.dart';
import 'badge_unlock_screen.dart';

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MilestonesCubit()..load(),
      child: const _MilestonesView(),
    );
  }
}

class _MilestonesView extends StatelessWidget {
  const _MilestonesView();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<MilestonesCubit, MilestonesState>(
      builder: (ctx, state) {
        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: withHaptic(() => Navigator.pop(ctx)),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18, color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.milestonesTitle,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Header row
                              Row(
                                children: [
                                  Expanded(
                                    child: _TopCard(
                                      icon: Image.asset('assets/streaks.png', width: 36, height: 36),
                                      label: l10n.milestonesDayStreak,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _BadgeTopCard(
                                      earned: state.badgesEarned,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoBox(
                                      icon: Image.asset('assets/streaks.png', width: 20, height: 20),
                                      value:
                                          l10n.milestonesLongestStreak(state.longestStreak),
                                      label: l10n.milestonesLongestStreakLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _BadgeProgressBox(
                                      earned: state.badgesEarned,
                                      total: state.totalBadges,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // How Streaks Work
                              if (state.showHowStreaksWork) ...[
                                _HowStreaksWork(
                                  onDismiss: () => ctx
                                      .read<MilestonesCubit>()
                                      .dismissHowStreaksWork(),
                                ),
                                const SizedBox(height: 20),
                              ],
                              // Streak Badges
                              Text(
                                l10n.milestonesStreakBadges,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BadgeGrid(badges: state.streakBadges),
                              const SizedBox(height: 24),
                              // Achievement Badges
                              Text(
                                l10n.milestonesAchievementBadges,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BadgeGrid(badges: state.achievementBadges),
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

class _TopCard extends StatelessWidget {
  final Widget icon;
  final String label;

  const _TopCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTopCard extends StatelessWidget {
  final int earned;

  const _BadgeTopCard({required this.earned});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          HexagonBadge(
            label: '$earned',
            earned: earned > 0,
            size: 56,
            earnedColor: const Color(0xFFB8860B),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.milestonesBadgesEarned,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const _InfoBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeProgressBox extends StatelessWidget {
  final int earned;
  final int total;

  const _BadgeProgressBox({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).milestonesBadgeCount(earned, total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? earned / total : 0,
              minHeight: 6,
              backgroundColor: c.separator,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFB8860B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowStreaksWork extends StatelessWidget {
  final VoidCallback onDismiss;

  const _HowStreaksWork({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: c.textSecondary),
              const SizedBox(width: 8),
              Text(
                l10n.milestonesHowStreaksWork,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: withHaptic(onDismiss),
                child: Icon(Icons.close,
                    size: 18, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.milestonesStreakExplanation,
            style: TextStyle(
              fontSize: 13,
              color: c.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<BadgeModel> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: badges.length,
      itemBuilder: (ctx, i) => _BadgeCell(badge: badges[i]),
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final BadgeModel badge;

  const _BadgeCell({required this.badge});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: badge.earned
          ? withHaptic(() => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BadgeUnlockScreen(badge: badge),
                ),
              ))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HexagonBadge(
            label: badge.displayValue,
            earned: badge.earned,
            size: 72,
            earnedColor: badge.kind == BadgeKind.streak
                ? const Color(0xFFE05C1A)
                : const Color(0xFF7B61FF),
          ),
          const SizedBox(height: 8),
          Text(
            localizedBadgeName(l10n, badge.id),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            localizedBadgeReq(l10n, badge.id),
            style: TextStyle(
              fontSize: 10,
              color: c.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
