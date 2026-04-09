import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../missions/models/mission.dart';
import '../services/alarm_firestore_service.dart';
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

  /// Restores alarms from Firestore (source of truth) and reschedules any
  /// that are no longer registered in the native alarm system.
  Future<void> _syncAlarms() async {
    final firestoreAlarms = await AlarmFirestoreService.getAlarms();

    // Collect native alarm ids
    final rawNative = await _plugin.getAlarms();
    final nativeIds = <String>{};
    for (final item in rawNative) {
      final id = item['id'] as String?;
      final schedule = item['schedule'] as Map?;
      if (id == null || schedule == null) continue;
      if (schedule['type'] != 'fixed') continue;
      nativeIds.add(id);
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final resolved = <AppAlarmEntry>[];

    for (final alarm in firestoreAlarms) {
      // Disabled alarms or alarms already scheduled natively need no action
      if (!alarm.isEnabled || nativeIds.contains(alarm.id)) {
        resolved.add(alarm);
        continue;
      }

      // Alarm is enabled but missing from native — reschedule it
      var scheduled = alarm.dateTime;
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final info = missionInfoFor(alarm.missionType);
      final newId = await _plugin.scheduleOneShotAlarm(
        timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
        label: alarm.name.isNotEmpty ? alarm.name : 'Levio — ${info.name} mission',
        secondaryButton: AlarmButton(
          text: info.name,
          textColor: '#FFFFFF',
          systemImageName: _systemImageFor(alarm.missionType),
        ),
        secondaryButtonBehavior: AlarmSecondaryButtonBehavior.snooze(300),
      );

      // Update SharedPreferences (alarm service reads these on ring)
      await prefs.remove(_missionKey(alarm.id));
      await prefs.remove(_nameKey(alarm.id));
      await prefs.remove(_soundKey(alarm.id));
      await prefs.setString(_missionKey(newId), alarm.missionType.name);
      await prefs.setString(_nameKey(newId), alarm.name);
      await prefs.setString(_soundKey(newId), alarm.soundId);

      // Update Firestore with new native id
      await AlarmFirestoreService.deleteAlarm(alarm.id);
      final rescheduled = alarm.copyWith(id: newId, dateTime: scheduled);
      await AlarmFirestoreService.saveAlarm(rescheduled);

      resolved.add(rescheduled);
    }

    emit(state.copyWith(alarms: resolved));
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
          : 'Levio — ${info.name} mission',
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
    await AlarmFirestoreService.saveAlarm(saved);
    emit(state.copyWith(alarms: [...state.alarms, saved]));
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final updated = state.alarms
        .map((a) => a.id == id ? a.copyWith(isEnabled: enabled) : a)
        .toList();
    emit(state.copyWith(alarms: updated));
    final alarm = updated.firstWhere((a) => a.id == id);
    await AlarmFirestoreService.saveAlarm(alarm);
  }

  Future<void> editAlarm(AppAlarmEntry old, AppAlarmEntry updated) async {
    await _plugin.cancelAlarm(alarmId: old.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_missionKey(old.id));
    await prefs.remove(_nameKey(old.id));
    await prefs.remove(_soundKey(old.id));
    await prefs.remove('challenge_${old.id}');
    await AlarmFirestoreService.deleteAlarm(old.id);

    var scheduled = kDebugMode
        ? DateTime.now().add(const Duration(seconds: 5))
        : updated.dateTime;
    if (!kDebugMode && scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final info = missionInfoFor(updated.missionType);
    final newId = await _plugin.scheduleOneShotAlarm(
      timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
      label: updated.name.isNotEmpty
          ? updated.name
          : 'Levio — ${info.name} mission',
      secondaryButton: AlarmButton(
        text: info.name,
        textColor: '#FFFFFF',
        systemImageName: _systemImageFor(updated.missionType),
      ),
      secondaryButtonBehavior: AlarmSecondaryButtonBehavior.snooze(300),
    );

    await prefs.setString(_missionKey(newId), updated.missionType.name);
    await prefs.setString(_nameKey(newId), updated.name);
    await prefs.setString(_soundKey(newId), updated.soundId);

    final saved = updated.copyWith(id: newId, dateTime: scheduled);
    await AlarmFirestoreService.saveAlarm(saved);
    emit(state.copyWith(
      alarms: state.alarms.map((a) => a.id == old.id ? saved : a).toList(),
    ));
  }

  Future<void> removeAlarm(String id) async {
    await _plugin.cancelAlarm(alarmId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_missionKey(id));
    await prefs.remove(_nameKey(id));
    await prefs.remove(_soundKey(id));
    await prefs.remove('challenge_$id');
    await AlarmFirestoreService.deleteAlarm(id);
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
