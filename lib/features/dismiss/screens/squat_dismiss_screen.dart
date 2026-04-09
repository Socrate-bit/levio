import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/squat_cubit.dart';
import '../cubit/pushup_state.dart';
import '../widgets/skeleton_painter.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';

class SquatDismissScreen extends StatelessWidget {
  final String alarmId;
  final String alarmLabel;

  const SquatDismissScreen({
    super.key,
    required this.alarmId,
    this.alarmLabel = 'Alarm #1',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SquatCubit(targetReps: 20)..startSession(),
      child: _SquatDismissView(alarmId: alarmId, alarmLabel: alarmLabel),
    );
  }
}

class _SquatDismissView extends StatefulWidget {
  final String alarmId;
  final String alarmLabel;

  const _SquatDismissView({
    required this.alarmId,
    required this.alarmLabel,
  });

  @override
  State<_SquatDismissView> createState() => _SquatDismissViewState();
}

class _SquatDismissViewState extends State<_SquatDismissView> {
  static const int _target = 20;
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
    return BlocConsumer<SquatCubit, PushUpState>(
      listener: (context, state) async {
        if (state is SessionGoalReached) {
          await FlutterAlarmkit().stopAlarm(alarmId: widget.alarmId);
          final elapsed = DateTime.now().difference(_startTime).inSeconds;
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => WakeupCompleteScreen(
                  timeTakenSeconds: elapsed,
                  session: WakeupSession(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    timestamp: DateTime.now(),
                    timeTakenSeconds: elapsed,
                    missionType: MissionType.squats,
                  ),
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
            body: SafeArea(
              child: Column(
                children: [
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.orange),
                    ),
                  ),
                ],
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
                        BlocSelector<SquatCubit, PushUpState,
                            (List<DetectedPose>, int, int)>(
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
                        '${state.repCount} / $_target',
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
