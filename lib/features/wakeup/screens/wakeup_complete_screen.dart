import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../milestones/models/badge_model.dart';
import '../../milestones/screens/badge_unlock_screen.dart';
import '../../milestones/services/streak_service.dart';
import '../../missions/models/mission.dart';
import '../../subscription/services/analytics_service.dart';
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
  // Whether the completed alarm is a sleep (bedtime) alarm — drives which sun
  // animation plays. Captured up front since one-time alarms get disabled below.
  bool _isSleep = false;
  final _confetti =
      ConfettiController(duration: const Duration(milliseconds: 280));

  @override
  void initState() {
    super.initState();
    _isSleep = context
        .read<AlarmCubit>()
        .state
        .alarms
        .any((a) => a.id == widget.alarmId && a.isSleep);
    _processWakeup();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
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
          missionType: widget.missionType,
        );
      }

      final result = await StreakService.onWakeupCompleted(
        sessionId: session?.id ?? widget.alarmId,
        soundId: session?.soundId ?? 'default',
        timeTakenSeconds: widget.timeTakenSeconds,
        missionType: widget.missionType,
        isSleep: _isSleep,
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

        // Fire confetti only after badge unlocks finish — otherwise the
        // animation runs while badges cover the screen and is missed.
        if (mounted) {
          _confetti.play();
          HapticFeedback.heavyImpact();
          // Quick double-tap haptic for an "explosion" feel.
          Future.delayed(
            const Duration(milliseconds: 90),
            HapticFeedback.mediumImpact,
          );
        }
      }
    } catch (e, st) {
      AnalyticsService.trackError('WakeupCompleteScreen._processWakeup', e, st);
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
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  const Spacer(),
                  _SunAnimation(isSleep: _isSleep),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.wakeupCongratulations,
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.wakeupThanks,
                    style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 36.h),
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
                        SizedBox(width: 12.w),
                        _StatBox(
                          icon: '🔥',
                          value: '$_streak',
                          label: l10n.wakeupDayStreak,
                        ),
                        SizedBox(width: 12.w),
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
                          style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.chevron_right, size: 18.sp, color: c.textSecondary),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: withHaptic(() =>
                        Navigator.of(context).popUntil((route) => route.isFirst)),
                    child: Text(l10n.wakeupContinue),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.9,
                numberOfParticles: 18,
                maxBlastForce: 50,
                minBlastForce: 30,
                gravity: 0.45,
                shouldLoop: false,
                colors: [
                  c.purpleDeep,
                  AppColors.orange,
                  Colors.amber,
                  Colors.greenAccent,
                  Colors.lightBlueAccent,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Looping sun animation shown on the completion screen: a sleepy sun for sleep
/// (bedtime) alarms and a happy sun for wake-up alarms. Falls back to the static
/// app icon if the GIF can't be loaded.
class _SunAnimation extends StatelessWidget {
  final bool isSleep;

  const _SunAnimation({required this.isSleep});

  @override
  Widget build(BuildContext context) {
    final asset = isSleep
        ? 'assets/animations/sleepy_sun.gif'
        : 'assets/animations/happy_sun.gif';
    return SizedBox(
      width: 240.w,
      height: 240.h,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[WakeupCompleteScreen] sun animation failed: $error');
          AnalyticsService.trackError(
            'WakeupCompleteScreen.sunAnimation',
            error,
            stackTrace,
          );
          return Image.asset('assets/icon.png');
        },
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
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 22.sp)),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
