import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/pushup_cubit.dart';
import '../../missions/models/mission.dart';
import 'rep_exercise_dismiss_view.dart';

class AlarmDismissScreen extends StatelessWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final int repCount;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const AlarmDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.repCount = 5,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PushUpCubit(targetReps: repCount)..startSession(),
      child: RepExerciseDismissView<PushUpCubit>(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        target: repCount,
        missionType: MissionType.pushUps,
        mirrorCamera: true,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      ),
    );
  }
}
