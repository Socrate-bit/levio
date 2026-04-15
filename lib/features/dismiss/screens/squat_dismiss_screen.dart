import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/squat_cubit.dart';
import '../../missions/models/mission.dart';
import 'rep_exercise_dismiss_view.dart';

class SquatDismissScreen extends StatelessWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final int repCount;
  final VoidCallback? onComplete;
  final bool manageAlarm;
  final bool isPreview;

  const SquatDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.repCount = 10,
    this.onComplete,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SquatCubit(targetReps: repCount)..startSession(),
      child: RepExerciseDismissView<SquatCubit>(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        target: repCount,
        missionType: MissionType.squats,
        mirrorCamera: true,
        onComplete: onComplete,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      ),
    );
  }
}
