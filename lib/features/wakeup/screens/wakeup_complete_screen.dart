import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../milestones/models/badge_model.dart';
import '../../milestones/screens/badge_unlock_screen.dart';
import '../../milestones/services/streak_service.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/services/history_service.dart';
import 'daily_quote_screen.dart';

class WakeupCompleteScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final int timeTakenSeconds;
  final MissionType? missionType;

  const WakeupCompleteScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    required this.timeTakenSeconds,
    this.missionType,
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
      // Disable one-time alarms immediately so they don't get rescheduled.
      final cubit = context.read<AlarmCubit>();
      final isOneTime = cubit.state.alarms
          .any((a) => a.id == widget.alarmId && a.isOneTime);
      if (isOneTime) await cubit.toggleAlarm(widget.alarmId, false);

      final session = await HistoryService.getPendingSession(widget.alarmId);

      if (session != null) {
        await HistoryService.completeSession(
          session.id,
          timeTakenSeconds: widget.timeTakenSeconds,
        );
      }

      final result = await StreakService.onWakeupCompleted(
        sessionId: session?.id ?? widget.alarmId,
        soundId: session?.soundId ?? 'default',
        timeTakenSeconds: widget.timeTakenSeconds,
        missionType: widget.missionType,
      );
      final total = await HistoryService.getTotalWakeups();

      if (mounted) {
        setState(() {
          _streak = result.newStreak;
          _totalWakeups = total;
          _newBadges = result.newlyEarnedBadges;
          _loading = false;
        });

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
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Image.asset('assets/icon.png', width: 120, height: 120),
              const SizedBox(height: 24),
              Text(
                l10n.wakeupCongratulations,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.wakeupThanks,
                style: TextStyle(fontSize: 14, color: c.textSecondary),
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
                      label: l10n.wakeupTimeTaken,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      icon: '🔥',
                      value: '$_streak',
                      label: l10n.wakeupDayStreak,
                    ),
                    const SizedBox(width: 12),
                    _StatBox(
                      icon: '☀️',
                      value: '$_totalWakeups',
                      label: l10n.wakeupWakeups,
                    ),
                  ],
                ),
              const Spacer(),
              GestureDetector(
                onTap: withHaptic(() => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyQuoteScreen(),
                    fullscreenDialog: true,
                  ),
                )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.wakeupDailyQuote,
                      style: TextStyle(fontSize: 15, color: c.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: c.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: withHaptic(() =>
                    Navigator.of(context).popUntil((route) => route.isFirst)),
                child: Text(l10n.wakeupContinue),
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
    final c = AppColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
