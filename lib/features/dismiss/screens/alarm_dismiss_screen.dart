import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/pushup_cubit.dart';
import '../../missions/models/mission.dart';
import 'rep_exercise_dismiss_view.dart';

class AlarmDismissScreen extends StatelessWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;

  const AlarmDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PushUpCubit(targetReps: 10)..startSession(),
      child: RepExerciseDismissView<PushUpCubit>(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        target: 10,
        missionType: MissionType.pushUps,
        mirrorCamera: true,
      ),
    );
  }
}
