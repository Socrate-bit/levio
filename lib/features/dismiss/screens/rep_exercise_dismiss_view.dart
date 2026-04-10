import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../alarms/services/alarm_channel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/pushup_state.dart';
import '../widgets/skeleton_painter.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';

/// Shared dismiss-screen UI for rep-based exercises (push-ups, squats, …).
///
/// [C] must be a [Cubit<PushUpState>] already provided above this widget.
class RepExerciseDismissView<C extends Cubit<PushUpState>>
    extends StatefulWidget {
  final String alarmId;
  final String alarmLabel;
  final int target;
  final MissionType missionType;

  /// Set to true when using the front camera so the preview is mirrored.
  final bool mirrorCamera;

  const RepExerciseDismissView({
    super.key,
    required this.alarmId,
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
    extends State<RepExerciseDismissView<C>> {
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BlocConsumer<C, PushUpState>(
      listener: (context, state) async {
        if (state is SessionGoalReached) {
          await AlarmChannel.dismissAlarm(widget.alarmId);
          final elapsed = DateTime.now().difference(_startTime).inSeconds;
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => WakeupCompleteScreen(
                  alarmId: widget.alarmId,
                  timeTakenSeconds: elapsed,
                  missionType: widget.missionType,
                ),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is CameraLoading || state is PushUpInitial) {
          return Scaffold(
            backgroundColor: c.background,
            body: const SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
            ),
          );
        }

        if (state is SessionActive) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: state.imageWidth / state.imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(state.camera),
                        BlocSelector<C, PushUpState,
                            (List<DetectedPose>, int, int)>(
                          selector: (s) => s is SessionActive
                              ? (s.poses, s.imageWidth, s.imageHeight)
                              : (const [], 0, 0),
                          builder: (context, data) {
                            final (poses, imgW, imgH) = data;
                            if (poses.isEmpty) return const SizedBox.shrink();
                            final painter = CustomPaint(
                              painter: SkeletonPainter(
                                poses: poses,
                                imageWidth: imgW,
                                imageHeight: imgH,
                              ),
                            );
                            return painter;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Rep counter
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${state.repCount} / ${widget.target}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Form feedback
                if (state.feedback != null)
                  Positioned(
                    bottom: 60,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        state.feedback!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return const Scaffold(backgroundColor: Colors.black);
      },
    );
  }
}
