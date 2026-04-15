import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levio/features/alarms/cubit/alarm_cubit.dart';
import '../../alarms/services/alarm_channel.dart';
import '../../wakeup/services/history_service.dart';
import '../../../shared/theme/app_theme.dart';

class SimpleDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;

  const SimpleDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
  });

  @override
  State<SimpleDismissScreen> createState() => _SimpleDismissScreenState();
}

class _SimpleDismissScreenState extends State<SimpleDismissScreen> {
  final _startTime = DateTime.now();
  String? _missionSnoozeId;
  bool _keepRinging = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initAlarm();
  }

  Future<void> _initAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    _keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;
    if (!_keepRinging) {
      await AlarmChannel.dismissAlarm(widget.nativeAlarmId);
      _missionSnoozeId = await AlarmChannel.scheduleMissionSnooze(
        nativeAlarmId: widget.nativeAlarmId,
        originalAlarmId: widget.alarmId,
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // Intentionally skips streak/badge calculation (no WakeupCompleteScreen).
  // Simple dismiss just records the session and returns home.
  Future<void> _dismiss() async {
    HapticFeedback.mediumImpact();

    await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
    await AlarmChannel.cleanupSnoozeLink(widget.nativeAlarmId);
    await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
    // Stop any alarm that may still be ringing (e.g. snooze fired during mission).
    await AlarmChannel.stopRinging();


    final elapsed = DateTime.now().difference(_startTime).inSeconds;

    // Disable one-time alarms so they don't get rescheduled.
    final isOneTime = context.read<AlarmCubit>().state.alarms
        .any((a) => a.id == widget.alarmId && a.isOneTime);
    if (isOneTime) {
      // ignore: use_build_context_synchronously
      await context.read<AlarmCubit>().toggleAlarm(widget.alarmId, false);
    }

    // Complete the pending session for history, but skip streak validation.
    final session = await HistoryService.getPendingSession(widget.alarmId);
    if (session != null) {
      await HistoryService.completeSession(
        session.id,
        timeTakenSeconds: elapsed,
      );
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⏰', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 24),
                    Text(
                      widget.alarmLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: _dismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Stop Alarm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
