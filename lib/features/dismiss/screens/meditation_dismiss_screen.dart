import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../missions/models/mission.dart';
import '../../subscription/services/analytics_service.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../widgets/levio_brand_header.dart';

/// Remote guided-meditation audio (Firebase Storage download URL).
const _meditationUrl =
    'https://firebasestorage.googleapis.com/v0/b/levio-ef67e.firebasestorage.app/o/meditation_1_FR.mp3?alt=media&token=0923afa4-7a75-4a6c-ba30-81cd401ab3a6';

/// Meditation mission. Plays a guided meditation audio and completes after a
/// fixed minimum listen of 2 minutes (or when the track ends, whichever comes
/// first). The user cannot skip ahead.
class MeditationDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const MeditationDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<MeditationDismissScreen> createState() =>
      _MeditationDismissScreenState();
}

class _MeditationDismissScreenState extends State<MeditationDismissScreen> {
  // Required minimum listen duration before the mission completes.
  static const _requiredDuration = Duration(minutes: 2);

  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;
  Duration _elapsed = Duration.zero;
  bool _finished = false;
  bool _error = false;
  final _startTime = DateTime.now();
  AlarmCascadeController? _cascade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
    _start();
  }

  Future<void> _start() async {
    try {
      // Drop any listeners from a previous attempt before re-subscribing.
      await _positionSub?.cancel();
      await _completeSub?.cancel();
      await _player.setReleaseMode(ReleaseMode.stop);
      // Position updates drive the countdown AND act as the liveness signal
      // for the inactivity watchdog during this passive mission.
      _positionSub = _player.onPositionChanged.listen(_onPosition);
      _completeSub = _player.onPlayerComplete.listen((_) => _finish());
      await _player.play(UrlSource(_meditationUrl));
    } catch (e, st) {
      AnalyticsService.trackError('MeditationDismissScreen._start', e, st);
      if (mounted) setState(() => _error = true);
    }
  }

  void _onPosition(Duration position) {
    if (!mounted || _finished) return;
    widget.onProgress?.call();
    _cascade?.reportProgress();
    setState(() => _elapsed = position);
    if (position >= _requiredDuration) _finish();
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    await _player.stop();
    HapticFeedback.mediumImpact();

    if (widget.isPreview) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    await _cascade?.finish();

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            nativeAlarmId: widget.nativeAlarmId,
            timeTakenSeconds: elapsed,
            missionType: MissionType.meditation,
          ),
        ),
      );
    }
  }

  Future<void> _retry() async {
    setState(() => _error = false);
    await _start();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _formatRemaining() {
    final remaining = _requiredDuration - _elapsed;
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final m = clamped.inMinutes;
    final s = clamped.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final progress =
        (_elapsed.inMilliseconds / _requiredDuration.inMilliseconds)
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.meditationTitle,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Text(
                            l10n.meditationInstruction,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(height: 48.h),
                        SizedBox(
                          width: 200.w,
                          height: 200.w,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200.w,
                                height: 200.w,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  backgroundColor: c.separator,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.orange,
                                  ),
                                ),
                              ),
                              if (_error)
                                GestureDetector(
                                  onTap: _retry,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        size: 36.sp,
                                        color: c.textSecondary,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        l10n.meditationRetry,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  _formatRemaining(),
                                  style: TextStyle(
                                    fontSize: 40.sp,
                                    fontWeight: FontWeight.bold,
                                    color: c.textPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isPreview)
              Positioned(
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: c.textPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
