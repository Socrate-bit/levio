import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../missions/models/mission.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

  final _plugin = FlutterAlarmkit();

  static String _missionKey(String id) => 'mission_$id';
  static String _nameKey(String id) => 'name_$id';
  static String _soundKey(String id) => 'sound_$id';

  Future<void> _init() async {
    await _plugin.requestAuthorization();
    await _syncAlarms();
  }

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

      final missionRaw =
          prefs.getString(_missionKey(id)) ?? prefs.getString('challenge_$id');
      final mission = missionRaw != null
          ? missionTypeFromString(missionRaw)
          : MissionType.pushUps;
      final name = prefs.getString(_nameKey(id)) ?? '';
      final soundId = prefs.getString(_soundKey(id)) ?? 'default';

      entries.add(AppAlarmEntry(
        id: id,
        dateTime: DateTime.fromMillisecondsSinceEpoch(tsMs.toInt()),
        missionType: mission,
        name: name,
        soundId: soundId,
      ));
    }
    emit(state.copyWith(alarms: entries));
  }

  Future<void> addAlarm(AppAlarmEntry entry) async {
    var scheduled = kDebugMode
        ? DateTime.now().add(const Duration(seconds: 5))
        : entry.dateTime;
    if (!kDebugMode && scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final info = missionInfoFor(entry.missionType);
    final id = await _plugin.scheduleOneShotAlarm(
      timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
      label: entry.name.isNotEmpty
          ? entry.name
          : 'Wayk — ${info.name} mission',
      secondaryButton: AlarmButton(
        text: info.name,
        textColor: '#FFFFFF',
        systemImageName: _systemImageFor(entry.missionType),
      ),
      secondaryButtonBehavior: AlarmSecondaryButtonBehavior.snooze(300),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_missionKey(id), entry.missionType.name);
    await prefs.setString(_nameKey(id), entry.name);
    await prefs.setString(_soundKey(id), entry.soundId);

    final saved = entry.copyWith(id: id, dateTime: scheduled);
    emit(state.copyWith(alarms: [...state.alarms, saved]));
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    emit(state.copyWith(
      alarms: state.alarms
          .map((a) => a.id == id ? a.copyWith(isEnabled: enabled) : a)
          .toList(),
    ));
  }

  Future<void> removeAlarm(String id) async {
    await _plugin.cancelAlarm(alarmId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_missionKey(id));
    await prefs.remove(_nameKey(id));
    await prefs.remove(_soundKey(id));
    await prefs.remove('challenge_$id');
    emit(state.copyWith(
      alarms: state.alarms.where((a) => a.id != id).toList(),
    ));
  }

  String _systemImageFor(MissionType type) {
    switch (type) {
      case MissionType.shakePhone:
        return 'iphone.radiowaves.left.and.right';
      case MissionType.pushUps:
      case MissionType.squats:
        return 'figure.strengthtraining.traditional';
      case MissionType.skyPhoto:
      case MissionType.makeBed:
      case MissionType.objectHunt:
      case MissionType.petHunt:
      case MissionType.natureHunt:
      case MissionType.touchGrass:
        return 'camera.fill';
      case MissionType.bibleVerse:
      case MissionType.affirmation:
        return 'mic.fill';
      case MissionType.math:
        return 'function';
      case MissionType.random:
        return 'dice.fill';
    }
  }
}
