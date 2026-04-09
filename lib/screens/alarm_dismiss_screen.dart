import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pushup_cubit.dart';
import '../bloc/pushup_state.dart';
import '../widgets/skeleton_painter.dart';

class AlarmDismissScreen extends StatelessWidget {
  final String alarmId;

  const AlarmDismissScreen({super.key, required this.alarmId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PushUpCubit(targetReps: 10)..startSession(),
      child: _AlarmDismissView(alarmId: alarmId),
    );
  }
}

class _AlarmDismissView extends StatefulWidget {
  final String alarmId;
  const _AlarmDismissView({required this.alarmId});

  @override
  State<_AlarmDismissView> createState() => _AlarmDismissViewState();
}

class _AlarmDismissViewState extends State<_AlarmDismissView> {
  static const int _target = 10;

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
    return BlocConsumer<PushUpCubit, PushUpState>(
      listener: (context, state) async {
        if (state is SessionGoalReached) {
          await FlutterAlarmkit().stopAlarm(alarmId: widget.alarmId);
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
      builder: (context, state) {
        if (state is CameraLoading || state is PushUpInitial) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
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
                        BlocSelector<PushUpCubit, PushUpState,
                            (List<DetectedPose>, int, int)>(
                          selector: (s) => s is SessionActive
                              ? (s.poses, s.imageWidth, s.imageHeight)
                              : (const [], 0, 0),
                          builder: (context, data) {
                            final (poses, imgW, imgH) = data;
                            if (poses.isEmpty) return const SizedBox.shrink();
                            return Transform(
                              alignment: Alignment.center,
                              transform:
                                  Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
                              child: CustomPaint(
                                painter: SkeletonPainter(
                                  poses: poses,
                                  imageWidth: imgW,
                                  imageHeight: imgH,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Alarm banner
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.redAccent.withAlpha(220),
                    padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
                    child: const Text(
                      'ALARM — Do 10 push-ups to dismiss',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Rep counter
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${state.repCount}/$_target',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        state.feedback!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
