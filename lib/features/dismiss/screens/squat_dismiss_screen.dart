import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/squat_cubit.dart';
import '../../missions/models/mission.dart';
import 'rep_exercise_dismiss_view.dart';

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
      child: RepExerciseDismissView<SquatCubit>(
        alarmId: alarmId,
        alarmLabel: alarmLabel,
        target: 20,
        missionType: MissionType.squats,
        mirrorCamera: true,
      ),
    );
  }
}
