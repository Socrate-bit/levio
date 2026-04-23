import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/pushup_state.dart';
import '../widgets/skeleton_painter.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../widgets/levio_brand_header.dart';

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
  final bool mirrorCamera;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const RepExerciseDismissView({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    required this.alarmLabel,
    required this.target,
    required this.missionType,
    this.mirrorCamera = false,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
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
  AlarmCascadeController? _cascade;

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
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _triggerPulse(int repCount) {
    if (repCount != _lastRepCount) {
      _lastRepCount = repCount;
      widget.onProgress?.call();
      _cascade?.reportProgress();
      _pulseController.forward().then((_) => _pulseController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, PushUpState>(
      listener: (context, state) async {
        if (state is SessionGoalReached) {
          if (widget.isPreview) {
            if (context.mounted) Navigator.of(context).pop();
            return;
          }

          if (widget.onComplete != null) {
            widget.onComplete!();
            return;
          }

          await _cascade?.finish();

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
          child = Scaffold(
            key: const ValueKey('blank'),
            backgroundColor: AppColors.of(context).background,
          );
        }

        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: child,
        );

        // Preview mode: overlay close button
        if (widget.isPreview) {
          return Stack(
            children: [
              content,
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: GestureDetector(
                      onTap: withHaptic(() => Navigator.of(context).pop()),
                      child: Container(
                        width: 36.w,
                        height: 36.h,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 18.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return content;
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.orange,
              strokeWidth: 2.5,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.dismissRepStarting,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 14.sp,
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

  String _feedbackText(BuildContext context, FeedbackKey key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case FeedbackKey.moveIntoFrame:
        return l10n.dismissFeedbackMoveIntoFrame;
      case FeedbackKey.keepGoing:
        return l10n.dismissFeedbackKeepGoing;
      case FeedbackKey.pushupPosition:
        return l10n.dismissFeedbackPushupPosition;
      case FeedbackKey.startPushups:
        return l10n.dismissFeedbackStartPushups;
      case FeedbackKey.pushupGoDeeper:
        return l10n.dismissFeedbackPushupGoDeeper;
      case FeedbackKey.squatPosition:
        return l10n.dismissFeedbackSquatPosition;
      case FeedbackKey.startSquats:
        return l10n.dismissFeedbackStartSquats;
      case FeedbackKey.squatGoDeeper:
        return l10n.dismissFeedbackSquatGoDeeper;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = (state.repCount / target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const LevioBrandHeader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                l10n.dismissRepPrompt(target, localizedMissionName(l10n, missionType)),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ),

            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: AspectRatio(
                  aspectRatio: state.imageWidth / state.imageHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(state.camera),

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

                        Positioned(
                          top: 14.h,
                          left: 16.w,
                          right: 16.w,
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
                                    padding: EdgeInsets.symmetric(
                                      vertical: 7.h,
                                      horizontal: 14.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          state.feedbackType ==
                                              FeedbackType.positive
                                          ? AppColors.success.withAlpha(200)
                                          : AppColors.error.withAlpha(200),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      _feedbackText(context, state.feedback!),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.sp,
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

            _RepCounter(
              repCount: state.repCount,
              target: target,
              progress: progress,
              pulseAnimation: pulseAnimation,
              textColor: c.textPrimary,
              subtitleColor: c.textSecondary,
              trackColor: c.separator,
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
  final Color textColor;
  final Color subtitleColor;
  final Color trackColor;

  const _RepCounter({
    required this.repCount,
    required this.target,
    required this.progress,
    required this.pulseAnimation,
    required this.textColor,
    required this.subtitleColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ScaleTransition(
      scale: pulseAnimation,
      child: SizedBox(
        width: 160.w,
        height: 160.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(160.w, 160.h),
              painter: _ArcPainter(progress: progress, trackColor: trackColor),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$repCount',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 52.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.dismissRepOf(target),
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14.sp,
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
  final Color trackColor;

  const _ArcPainter({required this.progress, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;
    const startAngle = -math.pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
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
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.trackColor != trackColor;
}
