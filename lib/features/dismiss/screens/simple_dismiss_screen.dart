import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/features/alarms/cubit/alarm_cubit.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../wakeup/services/history_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/levio_brand_header.dart';

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
  late final AlarmCascadeController _cascade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _cascade = AlarmCascadeController(alarmId: widget.alarmId);
    _cascade.start();
  }

  @override
  void dispose() {
    _cascade.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // Intentionally skips streak/badge calculation (no WakeupCompleteScreen).
  // Simple dismiss just records the session and returns home.
  Future<void> _dismiss() async {
    HapticFeedback.mediumImpact();

    await _cascade.finish();

    final elapsed = DateTime.now().difference(_startTime).inSeconds;

    if (!mounted) return;
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            const LevioBrandHeader(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⏰', style: TextStyle(fontSize: 72.sp)),
                    SizedBox(height: 24.h),
                    Text(
                      widget.alarmLabel,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
              child: ElevatedButton(
                onPressed: _dismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.dismissStopAlarm,
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
