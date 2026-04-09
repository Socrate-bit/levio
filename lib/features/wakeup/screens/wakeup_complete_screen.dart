import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../milestones/models/badge_model.dart';
import '../../milestones/screens/badge_unlock_screen.dart';
import '../../milestones/services/streak_service.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../../wakeup/services/history_service.dart';
import 'daily_quote_screen.dart';

class WakeupCompleteScreen extends StatefulWidget {
  final int timeTakenSeconds;
  final WakeupSession session;

  const WakeupCompleteScreen({
    super.key,
    required this.timeTakenSeconds,
    required this.session,
  });

  @override
  State<WakeupCompleteScreen> createState() => _WakeupCompleteScreenState();
}

class _WakeupCompleteScreenState extends State<WakeupCompleteScreen> {
  int _streak = 0;
  int _totalWakeups = 0;
  List<BadgeModel> _newBadges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _processWakeup();
  }

  Future<void> _processWakeup() async {
    try {
      await HistoryService.saveSession(widget.session);
      final result = await StreakService.onWakeupCompleted(
        soundId: widget.session.soundId,
        timeTakenSeconds: widget.timeTakenSeconds,
        missionType: widget.session.missionType,
      );
      final total = await HistoryService.getTotalWakeups();

      if (mounted) {
        setState(() {
          _streak = result.newStreak;
          _totalWakeups = total;
          _newBadges = result.newlyEarnedBadges;
          _loading = false;
        });

        // Show badge unlock screens sequentially
        for (final badge in _newBadges) {
          if (!mounted) break;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BadgeUnlockScreen(badge: badge),
              fullscreenDialog: true,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              // Sun emoji mascot
              const Text('🌞', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                'Alarm turned off!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You joined 23 922 others waking up today',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              if (_loading)
                const CircularProgressIndicator()
              else
                Row(
                  children: [
                    _StatBox(
                      icon: '⏱',
                      value: _formatTime(widget.timeTakenSeconds),
                      label: 'Time Taken',
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      icon: '🔥',
                      value: '$_streak',
                      label: 'Day Streak',
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      icon: '☀️',
                      value: '$_totalWakeups',
                      label: 'Wakeups',
                    ),
                  ],
                ),
              const Spacer(),
              // Daily Quote
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyQuoteScreen(),
                    fullscreenDialog: true,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Daily Quote',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
