import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pushup_cubit.dart';
import '../bloc/pushup_state.dart';
import '../widgets/skeleton_painter.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PushUpCubit()..startSession(),
      child: const _SessionView(),
    );
  }
}

class _SessionView extends StatefulWidget {
  const _SessionView();

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
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
      listener: (context, state) {
        if (state is SessionComplete) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session done! ${state.repCount} push-ups'),
              duration: const Duration(seconds: 3),
            ),
          );
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
                // Camera + skeleton share the same AspectRatio so the overlay
                // maps 1:1 with the displayed preview (no distortion, no cropping).
                Center(
                  child: AspectRatio(
                    aspectRatio: state.imageWidth / state.imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Camera is a const subtree — never rebuilds on pose updates.
                        CameraPreview(state.camera),
                        // Only this layer repaints when poses change.
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

                // Rep count badge
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${state.repCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 96,
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

                // Form feedback banner
                if (state.feedback != null)
                  Positioned(
                    bottom: 100,
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

                // Stop button
                Positioned(
                  bottom: 32,
                  right: 24,
                  child: FloatingActionButton(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    onPressed: () =>
                        context.read<PushUpCubit>().stopSession(),
                    child: const Icon(Icons.stop),
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
