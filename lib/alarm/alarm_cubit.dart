import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

  final _plugin = FlutterAlarmkit();

  Future<void> _init() async {
    await _plugin.requestAuthorization();
    await _syncAlarms();
  }

  /// Syncs local state with what AlarmKit has scheduled.
  /// flutter_alarmkit's getAlarms() returns the schedule info, so we can
  /// reconstruct the DateTimes from the "timestamp" field.
  Future<void> _syncAlarms() async {
    final raw = await _plugin.getAlarms();
    final entries = <AppAlarmEntry>[];
    for (final item in raw) {
      final id = item['id'] as String?;
      final schedule = item['schedule'] as Map?;
      if (id == null || schedule == null) continue;
      if (schedule['type'] != 'fixed') continue;
      final tsMs = schedule['timestamp'] as double?;
      if (tsMs == null) continue;
      entries.add(AppAlarmEntry(
        id: id,
        dateTime: DateTime.fromMillisecondsSinceEpoch(tsMs.toInt()),
      ));
    }
    emit(state.copyWith(alarms: entries));
  }

  Future<void> addAlarm(DateTime dateTime) async {
    // If the picked time is in the past today, schedule for tomorrow.
    var scheduled = dateTime;
    if (scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final id = await _plugin.scheduleOneShotAlarm(
      timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
      label: 'Levio — do push-ups to dismiss',
    );

    emit(state.copyWith(
      alarms: [...state.alarms, AppAlarmEntry(id: id, dateTime: scheduled)],
    ));
  }

  Future<void> removeAlarm(String id) async {
    await _plugin.cancelAlarm(alarmId: id);
    emit(state.copyWith(
      alarms: state.alarms.where((a) => a.id != id).toList(),
    ));
  }
}
