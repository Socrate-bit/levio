import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alarms/services/alarm_channel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/pushup_state.dart';
import '../widgets/skeleton_painter.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/levio_brand_header.dart';

/// Shared dismiss-screen UI for rep-based exercises (push-ups, squats, …).
///
/// [C] must be a [Cubit<PushUpState>] already provided above this widget.
class RepExerciseDismissView<C extends Cubit<PushUpState>>
    extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final int target;
  final MissionType missionType;

  /// Set to true when using the front camera so the preview is mirrored.
  final bool mirrorCamera;

  const RepExerciseDismissView({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    required this.alarmLabel,
    required this.target,
    required this.missionType,
    this.mirrorCamera = false,
  });

  @override
  State<RepExerciseDismissView<C>> createState() =>
      _RepExerciseDismissViewState<C>();
}

class _RepExerciseDismissViewState<C extends Cubit<PushUpState>>
    extends State<RepExerciseDismissView<C>>
    with SingleTickerProviderStateMixin {
  final _startTime = DateTime.now();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _lastRepCount = 0;
  String? _missionSnoozeId;
  bool _keepRinging = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
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
    _pulseController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _triggerPulse(int repCount) {
    if (repCount != _lastRepCount) {
      _lastRepCount = repCount;
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, PushUpState>(
      listener: (context, state) async {
        if (state is SessionGoalReached) {
          await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
          await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
          await AlarmChannel.stopRinging();

          final elapsed = DateTime.now().difference(_startTime).inSeconds;
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => WakeupCompleteScreen(
                  alarmId: widget.alarmId,
                  nativeAlarmId: widget.nativeAlarmId,
                  timeTakenSeconds: elapsed,
                  missionType: widget.missionType,
                ),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        Widget child;
        if (state is CameraLoading ||
            state is PushUpInitial ||
            (state is SessionActive && !state.hasFirstFrame)) {
          child = const _LoadingView(key: ValueKey('loading'));
        } else if (state is SessionActive) {
          _triggerPulse(state.repCount);
          child = _ActiveSessionView<C>(
            key: const ValueKey('active'),
            state: state,
            target: widget.target,
            missionType: widget.missionType,
            pulseAnimation: _pulseAnimation,
          );
        } else {
          child = const Scaffold(
            key: ValueKey('blank'),
            backgroundColor: Colors.black,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: child,
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.orange,
              strokeWidth: 2.5,
            ),
            SizedBox(height: 16),
            Text(
              'Starting camera…',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionView<C extends Cubit<PushUpState>> extends StatelessWidget {
  final SessionActive state;
  final int target;
  final MissionType missionType;
  final Animation<double> pulseAnimation;

  const _ActiveSessionView({
    super.key,
    required this.state,
    required this.target,
    required this.missionType,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (state.repCount / target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const LevioBrandHeader(textColor: Colors.white),
            // "Do X Push-Ups" heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Do $target ${missionInfoFor(missionType).name} to stop the alarm',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),

            // Camera view — shown only after first frame, so dimensions are stable
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: state.imageWidth / state.imageHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Camera feed — fills the correctly-sized box, no distortion
                        CameraPreview(state.camera),

                        // Skeleton overlay
                        BlocSelector<
                          C,
                          PushUpState,
                          (List<DetectedPose>, int, int)
                        >(
                          selector: (s) => s is SessionActive
                              ? (s.poses, s.imageWidth, s.imageHeight)
                              : (const [], 0, 0),
                          builder: (context, data) {
                            final (poses, imgW, imgH) = data;
                            if (poses.isEmpty) return const SizedBox.shrink();
                            return CustomPaint(
                              painter: SkeletonPainter(
                                poses: poses,
                                imageWidth: imgW,
                                imageHeight: imgH,
                              ),
                            );
                          },
                        ),

                        // Subtle vignette
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(80),
                              ],
                            ),
                          ),
                        ),

                        // Form feedback — top of camera, discreet
                        Positioned(
                          top: 14,
                          left: 16,
                          right: 16,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -0.4),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: state.feedback != null
                                ? Container(
                                    key: ValueKey(state.feedback),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          state.feedbackType ==
                                              FeedbackType.positive
                                          ? AppColors.green.withAlpha(200)
                                          : const Color(
                                              0xFFE53935,
                                            ).withAlpha(200),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      state.feedback!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  )
                                : const SizedBox(key: ValueKey('empty')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Rep counter + progress arc
            _RepCounter(
              repCount: state.repCount,
              target: target,
              progress: progress,
              pulseAnimation: pulseAnimation,
            ),
          ],
        ),
      ),
    );
  }
}

class _RepCounter extends StatelessWidget {
  final int repCount;
  final int target;
  final double progress;
  final Animation<double> pulseAnimation;

  const _RepCounter({
    required this.repCount,
    required this.target,
    required this.progress,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: pulseAnimation,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress arc
            CustomPaint(
              size: const Size(160, 160),
              painter: _ArcPainter(progress: progress),
            ),

            // Count text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$repCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of $target',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;

  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withAlpha(20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      // Progress arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = AppColors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
