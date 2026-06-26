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

/// Meditation mission. Plays a guided meditation audio with play/pause control
/// and a full-track progress bar. The Finish button unlocks after a minimum
/// listen of 2 minutes (or when the track ends).
class MeditationDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;

  /// Minimum listen time in minutes before the Finish button unlocks.
  final int minMinutes;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const MeditationDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.minMinutes = 2,
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
  // Minimum listen before the Finish button unlocks (from config).
  late final Duration _requiredDuration = Duration(minutes: widget.minMinutes);

  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = true;
  bool _trackEnded = false;
  bool _finished = false;
  bool _error = false;
  final _startTime = DateTime.now();
  AlarmCascadeController? _cascade;

  bool get _canFinish => _position >= _requiredDuration || _trackEnded;

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
      await _player.setReleaseMode(ReleaseMode.stop);
      // Position updates drive the progress bar AND act as the liveness signal
      // for the inactivity watchdog while audio is playing.
      _positionSub = _player.onPositionChanged.listen(_onPosition);
      _durationSub = _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _total = d);
      });
      _completeSub = _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _trackEnded = true);
      });
      await _player.play(UrlSource(_meditationUrl));
      if (mounted) setState(() => _playing = true);
    } catch (e, st) {
      AnalyticsService.trackError('MeditationDismissScreen._start', e, st);
      if (mounted) setState(() => _error = true);
    }
  }

  void _onPosition(Duration position) {
    if (!mounted || _finished) return;
    widget.onProgress?.call();
    _cascade?.reportProgress();
    setState(() => _position = position);
  }

  Future<void> _togglePlay() async {
    widget.onProgress?.call();
    _cascade?.reportProgress();
    HapticFeedback.selectionClick();
    if (_playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  Future<void> _finish() async {
    if (_finished || !_canFinish) return;
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
    _durationSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _finishLabel(AppLocalizations l10n) {
    if (_canFinish) return l10n.gratefulnessFinish;
    final remaining = _requiredDuration - _position;
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    return l10n.meditationFinishIn(_fmt(clamped));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    // Full-track progress (0 until duration is known).
    final progress = _total.inMilliseconds > 0
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        Text(
                          l10n.meditationInstruction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: c.textSecondary,
                          ),
                        ),
                        SizedBox(height: 48.h),
                        // Play/pause control inside a ring showing track progress.
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
                                      Icon(Icons.refresh,
                                          size: 36.sp, color: c.textSecondary),
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
                                GestureDetector(
                                  onTap: _togglePlay,
                                  child: Container(
                                    width: 88.w,
                                    height: 88.w,
                                    decoration: const BoxDecoration(
                                      color: AppColors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _playing
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 44.sp,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Full-track time readout.
                        Text(
                          '${_fmt(_position)} / ${_fmt(_total)}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: c.textSecondary,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Finish button — unlocks after the minimum listen.
                Padding(
                  padding: EdgeInsets.fromLTRB(40.w, 0, 40.w, 24.h),
                  child: ElevatedButton(
                    onPressed: _canFinish ? _finish : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.separator,
                      disabledForegroundColor: c.textSecondary,
                      minimumSize: Size(double.infinity, 54.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _finishLabel(l10n),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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
