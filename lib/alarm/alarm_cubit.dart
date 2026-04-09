import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

  final _plugin = FlutterAlarmkit();

  static String _challengeKey(String id) => 'challenge_$id';

  Future<void> _init() async {
    await _plugin.requestAuthorization();
    await _syncAlarms();
  }

  /// Syncs local state with what AlarmKit has scheduled.
  /// flutter_alarmkit's getAlarms() returns the schedule info, so we can
  /// reconstruct the DateTimes from the "timestamp" field.
  Future<void> _syncAlarms() async {
    final raw = await _plugin.getAlarms();
    final prefs = await SharedPreferences.getInstance();
    final entries = <AppAlarmEntry>[];
    for (final item in raw) {
      final id = item['id'] as String?;
      final schedule = item['schedule'] as Map?;
      if (id == null || schedule == null) continue;
      if (schedule['type'] != 'fixed') continue;
      final tsMs = schedule['timestamp'] as double?;
      if (tsMs == null) continue;
      final challengeRaw = prefs.getString(_challengeKey(id));
      final challenge = ChallengeType.values.firstWhere(
        (c) => c.name == challengeRaw,
        orElse: () => ChallengeType.pushup,
      );
      entries.add(AppAlarmEntry(
        id: id,
        dateTime: DateTime.fromMillisecondsSinceEpoch(tsMs.toInt()),
        challenge: challenge,
      ));
    }
    emit(state.copyWith(alarms: entries));
  }

  Future<void> addAlarm(DateTime dateTime, ChallengeType challenge) async {
    var scheduled = dateTime;
    if (kDebugMode) {
      scheduled = DateTime.now().add(const Duration(seconds: 5));
    } else if (scheduled.isBefore(DateTime.now())) {
      // If the picked time is in the past today, schedule for tomorrow.
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final id = await _plugin.scheduleOneShotAlarm(
      timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
      label: switch (challenge) {
        ChallengeType.shake => 'Levio — shake to dismiss',
        ChallengeType.pushup => 'Levio — do push-ups to dismiss',
        ChallengeType.photo => 'Levio — take a photo to dismiss',
        ChallengeType.speech => 'Levio — speak to dismiss',
      },
      secondaryButton: AlarmButton(
        text: switch (challenge) {
          ChallengeType.shake => 'Shake',
          ChallengeType.pushup => 'Do push-up',
          ChallengeType.photo => 'Take photo',
          ChallengeType.speech => 'Speak',
        },
        textColor: '#FFFFFF',
        systemImageName: switch (challenge) {
          ChallengeType.shake => 'iphone.radiowaves.left.and.right',
          ChallengeType.pushup => 'figure.strengthtraining.traditional',
          ChallengeType.photo => 'camera.fill',
          ChallengeType.speech => 'mic.fill',
        },
      ),
      secondaryButtonBehavior: AlarmSecondaryButtonBehavior.stop,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_challengeKey(id), challenge.name);

    emit(state.copyWith(
      alarms: [
        ...state.alarms,
        AppAlarmEntry(id: id, dateTime: scheduled, challenge: challenge),
      ],
    ));
  }

  Future<void> removeAlarm(String id) async {
    await _plugin.cancelAlarm(alarmId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_challengeKey(id));
    emit(state.copyWith(
      alarms: state.alarms.where((a) => a.id != id).toList(),
    ));
  }
}
