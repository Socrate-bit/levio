import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../missions/models/mission.dart';
import '../services/alarm_channel.dart';
import '../services/alarm_firestore_service.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

  static String _missionKey(String id) => 'mission_$id';
  static String _nameKey(String id) => 'name_$id';
  static String _soundKey(String id) => 'sound_$id';

  Future<void> _init() async {
    await AlarmChannel.requestAuthorization();
    await _syncAlarms();
  }

  /// Restores alarms from Firestore (source of truth) and reschedules any
  /// that are no longer registered in the native alarm system.
  Future<void> _syncAlarms() async {
    final results = await Future.wait([
      AlarmFirestoreService.getAlarms(),
      AlarmChannel.getAlarmIds(),
      SharedPreferences.getInstance(),
      AlarmChannel.getPendingReschedules(),
    ]);
    final firestoreAlarms = results[0] as List<AppAlarmEntry>;
    final nativeIds = (results[1] as List<String>).toSet();
    final prefs = results[2] as SharedPreferences;
    // Reschedule signals written by StopAndRescheduleIntent while app was killed.
    final reschedules = results[3] as Map<String, String>;
    final now = DateTime.now();
    final resolved = <AppAlarmEntry>[];

    for (final alarm in firestoreAlarms) {
      if (reschedules.containsKey(alarm.id)) {
        final newId = reschedules[alarm.id]!;
        await _clearOldPrefs(prefs, alarm.id);
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = alarm.copyWith(
          id: newId,
          dateTime: now.add(const Duration(minutes: 5)),
        );
        await AlarmFirestoreService.saveAlarm(rescheduled);
        resolved.add(rescheduled);
        continue;
      }

      // Disabled or already scheduled natively — no action needed.
      if (!alarm.isEnabled || nativeIds.contains(alarm.id)) {
        resolved.add(alarm);
        continue;
      }

      // Alarm is enabled but missing from native — reschedule it.
      var scheduled = alarm.dateTime;
      if (scheduled.isBefore(now)) {
        final diff = now.difference(scheduled);
        scheduled = diff < const Duration(hours: 2)
            ? now.add(const Duration(minutes: 5))
            : scheduled.add(const Duration(days: 1));
      }

      final newId = await _scheduleNative(alarm, scheduled);

      await _clearOldPrefs(prefs, alarm.id);
      await _saveAlarmPrefs(prefs, newId, alarm);

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

    final id = await _scheduleNative(entry, scheduled, forceOneShot: kDebugMode);

    final prefs = await SharedPreferences.getInstance();
    await _saveAlarmPrefs(prefs, id, entry);

    final saved = entry.copyWith(id: id, dateTime: scheduled);
    await AlarmFirestoreService.saveAlarm(saved);
    emit(state.copyWith(alarms: [...state.alarms, saved]));
  }

  /// Updates only metadata (mission, sound, name) without rescheduling the
  /// native alarm. Use this for changes that don't affect the trigger time.
  Future<void> updateAlarmMeta(AppAlarmEntry updated) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveAlarmPrefs(prefs, updated.id, updated);
    await AlarmFirestoreService.saveAlarm(updated);
    emit(state.copyWith(
      alarms: state.alarms.map((a) => a.id == updated.id ? updated : a).toList(),
    ));
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final alarm = state.alarms.firstWhere((a) => a.id == id);

    if (!enabled) {
      await AlarmChannel.cancel(id);
      final updated = state.alarms
          .map((a) => a.id == id ? a.copyWith(isEnabled: false) : a)
          .toList();
      emit(state.copyWith(alarms: updated));
      await AlarmFirestoreService.saveAlarm(updated.firstWhere((a) => a.id == id));
    } else {
      var scheduled = alarm.dateTime;
      if (scheduled.isBefore(DateTime.now())) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final newId = await _scheduleNative(alarm, scheduled);

      final prefs = await SharedPreferences.getInstance();
      await _clearOldPrefs(prefs, id);
      await _saveAlarmPrefs(prefs, newId, alarm);

      await AlarmFirestoreService.deleteAlarm(id);
      final rescheduled = alarm.copyWith(id: newId, dateTime: scheduled, isEnabled: true);
      await AlarmFirestoreService.saveAlarm(rescheduled);

      emit(state.copyWith(
        alarms: state.alarms.map((a) => a.id == id ? rescheduled : a).toList(),
      ));
    }
  }

  Future<void> editAlarm(AppAlarmEntry old, AppAlarmEntry updated) async {
    await AlarmChannel.cancel(old.id);
    final prefs = await SharedPreferences.getInstance();
    await _clearOldPrefs(prefs, old.id);
    await AlarmFirestoreService.deleteAlarm(old.id);

    var scheduled = kDebugMode
        ? DateTime.now().add(const Duration(seconds: 5))
        : updated.dateTime;
    if (!kDebugMode && scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final newId = await _scheduleNative(updated, scheduled, forceOneShot: kDebugMode);

    await _saveAlarmPrefs(prefs, newId, updated);

    final saved = updated.copyWith(id: newId, dateTime: scheduled);
    await AlarmFirestoreService.saveAlarm(saved);
    emit(state.copyWith(
      alarms: state.alarms.map((a) => a.id == old.id ? saved : a).toList(),
    ));
  }

  Future<void> removeAlarm(String id) async {
    await AlarmChannel.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    await _clearOldPrefs(prefs, id);
    await AlarmFirestoreService.deleteAlarm(id);
    emit(state.copyWith(
      alarms: state.alarms.where((a) => a.id != id).toList(),
    ));
  }

  /// Schedules a native alarm, choosing one-shot or recurrent based on the
  /// entry's [repeatDays] and [isOneTime]. Pass [forceOneShot] to override
  /// (e.g. in debug mode).
  Future<String> _scheduleNative(
    AppAlarmEntry entry,
    DateTime scheduled, {
    bool forceOneShot = false,
  }) {
    final info = missionInfoFor(entry.missionType);
    final title = entry.name.isNotEmpty ? entry.name : 'Levio';
    final sfSymbol = _systemImageFor(entry.missionType);
    final secondaryLabel = info.name;
    // soundId is the filename (without .mp3) under assets/sounds/
    final soundPath = entry.soundId != 'default'
        ? 'assets/sounds/${entry.soundId}.mp3'
        : null;

    final isRecurrent =
        !forceOneShot && !entry.isOneTime && entry.repeatDays.any((d) => d);

    if (isRecurrent) {
      return AlarmChannel.scheduleRepeating(
        weekdayMask: AlarmChannel.toWeekdayMask(entry.repeatDays),
        hour: scheduled.hour,
        minute: scheduled.minute,
        title: title,
        sfSymbol: sfSymbol,
        secondaryLabel: secondaryLabel,
        soundPath: soundPath,
      );
    } else {
      return AlarmChannel.scheduleOneShot(
        timestampMs: scheduled.millisecondsSinceEpoch,
        title: title,
        sfSymbol: sfSymbol,
        secondaryLabel: secondaryLabel,
        soundPath: soundPath,
      );
    }
  }

  Future<void> _clearOldPrefs(SharedPreferences prefs, String id) async {
    await prefs.remove(_missionKey(id));
    await prefs.remove(_nameKey(id));
    await prefs.remove(_soundKey(id));
    await prefs.remove('challenge_$id');
  }

  Future<void> _saveAlarmPrefs(
    SharedPreferences prefs,
    String id,
    AppAlarmEntry entry,
  ) async {
    await prefs.setString(_missionKey(id), entry.missionType.name);
    await prefs.setString(_nameKey(id), entry.name);
    await prefs.setString(_soundKey(id), entry.soundId);
  }

  String _systemImageFor(MissionType type) {
    switch (type) {
      case MissionType.none:
        return 'alarm';
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
