import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../missions/models/mission.dart';
import '../services/alarm_channel.dart';
import '../services/alarm_firestore_service.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

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
      AlarmChannel.getPendingReschedules(),
      AlarmChannel.getPendingRecurringRestores(),
    ]);
    final firestoreAlarms = results[0] as List<AppAlarmEntry>;
    final nativeIds = (results[1] as List<String>).toSet();
    // Reschedule signals written by StopAndRescheduleIntent while app was killed.
    final reschedules = results[2] as Map<String, String>;
    final recurringRestores = results[3] as List<Map<String, dynamic>>;
    final now = DateTime.now();
    final resolved = <AppAlarmEntry>[];

    for (final alarm in firestoreAlarms) {
      if (reschedules.containsKey(alarm.id)) {
        final newId = reschedules[alarm.id]!;
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = alarm.copyWith(
          id: newId,
          dateTime: now.add(const Duration(minutes: 5)),
        );
        try {
          await AlarmFirestoreService.saveAlarm(rescheduled);
          resolved.add(rescheduled);
        } catch (e) {
          // Native alarm was already scheduled by intent; best-effort Firestore save.
          debugPrint('[AlarmCubit] _syncAlarms reschedule save failed: $e');
          resolved.add(rescheduled);
        }
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

      try {
        final newId = await _scheduleNative(alarm, scheduled);
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = alarm.copyWith(id: newId, dateTime: scheduled);
        await AlarmFirestoreService.saveAlarm(rescheduled);
        resolved.add(rescheduled);
      } catch (e) {
        debugPrint('[AlarmCubit] _syncAlarms reschedule failed for ${alarm.id}: $e');
        resolved.add(alarm);
      }
    }

    // Restore recurring alarms that were cancelled by StopAndRescheduleIntent.
    for (final restore in recurringRestores) {
      final originalId = restore['originalId'] as String?;
      if (originalId == null) continue;

      // Find the alarm data — it may be in resolved (from the reschedule branch above)
      // or still match one of the original Firestore entries.
      final match = resolved
          .where((a) =>
              !a.isOneTime && a.repeatDays.any((d) => d))
          .where((a) {
        // Match by reschedule: the snoozed alarm came from this originalId
        return reschedules[originalId] == a.id;
      }).firstOrNull;

      if (match != null) {
        try {
          final recurringId = await _scheduleNative(match, match.dateTime);
          final recurringEntry = match.copyWith(
            id: recurringId,
            isOneTime: false,
            isEnabled: true,
          );
          await AlarmFirestoreService.saveAlarm(recurringEntry);
          resolved.add(recurringEntry);
        } catch (e) {
          debugPrint('[AlarmCubit] recurring restore failed for $originalId: $e');
        }
      }
    }

    // Cancel orphaned native alarms not referenced by any Firestore entry.
    final resolvedIds = resolved.map((a) => a.id).toSet();
    for (final nativeId in nativeIds) {
      if (!resolvedIds.contains(nativeId)) {
        debugPrint('[AlarmCubit] cancelling orphaned native alarm $nativeId');
        try {
          await AlarmChannel.cancel(nativeId);
          await AlarmChannel.cleanupConfig(nativeId);
        } catch (e) {
          debugPrint('[AlarmCubit] orphan cleanup failed for $nativeId: $e');
        }
      }
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
    final saved = entry.copyWith(id: id, dateTime: scheduled);

    // Optimistic: show in UI immediately
    emit(state.copyWith(alarms: [...state.alarms, saved]));

    try {
      await AlarmFirestoreService.saveAlarm(saved);
    } catch (e) {
      // Rollback: remove from UI and cancel native
      emit(state.copyWith(
        alarms: state.alarms.where((a) => a.id != id).toList(),
      ));
      await AlarmChannel.cancel(id);
      rethrow;
    }
  }

  /// Updates only metadata (mission, sound, name) without rescheduling the
  /// native alarm. Use this for changes that don't affect the trigger time.
  Future<void> updateAlarmMeta(AppAlarmEntry updated) async {
    final previous = state.alarms.firstWhere((a) => a.id == updated.id);

    // Optimistic
    emit(state.copyWith(
      alarms: state.alarms.map((a) => a.id == updated.id ? updated : a).toList(),
    ));

    try {
      await AlarmFirestoreService.saveAlarm(updated);
    } catch (e) {
      // Rollback
      emit(state.copyWith(
        alarms: state.alarms.map((a) => a.id == updated.id ? previous : a).toList(),
      ));
      rethrow;
    }
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final alarm = state.alarms.firstWhere((a) => a.id == id);
    final previousAlarms = state.alarms;

    if (!enabled) {
      await AlarmChannel.cancel(id);
      final disabledAlarm = alarm.copyWith(isEnabled: false);

      // Optimistic
      emit(state.copyWith(
        alarms: state.alarms.map((a) => a.id == id ? disabledAlarm : a).toList(),
      ));

      try {
        await AlarmFirestoreService.saveAlarm(disabledAlarm);
      } catch (e) {
        // Rollback: re-schedule native and restore UI
        await _scheduleNative(alarm, alarm.dateTime);
        emit(state.copyWith(alarms: previousAlarms));
        rethrow;
      }
    } else {
      var scheduled = alarm.dateTime;
      if (scheduled.isBefore(DateTime.now())) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final newId = await _scheduleNative(alarm, scheduled);
      final rescheduled = alarm.copyWith(id: newId, dateTime: scheduled, isEnabled: true);

      // Optimistic
      emit(state.copyWith(
        alarms: state.alarms.map((a) => a.id == id ? rescheduled : a).toList(),
      ));

      try {
        await AlarmFirestoreService.deleteAlarm(id);
        await AlarmFirestoreService.saveAlarm(rescheduled);
      } catch (e) {
        // Rollback
        await AlarmChannel.cancel(newId);
        emit(state.copyWith(alarms: previousAlarms));
        rethrow;
      }
    }
  }

  Future<void> editAlarm(AppAlarmEntry old, AppAlarmEntry updated) async {
    final previousAlarms = state.alarms;

    await AlarmChannel.cancel(old.id);
    await AlarmChannel.cleanupConfig(old.id);

    var scheduled = kDebugMode
        ? DateTime.now().add(const Duration(seconds: 5))
        : updated.dateTime;
    if (!kDebugMode && scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final newId = await _scheduleNative(updated, scheduled, forceOneShot: kDebugMode);
    final saved = updated.copyWith(id: newId, dateTime: scheduled);

    // Optimistic
    emit(state.copyWith(
      alarms: state.alarms.map((a) => a.id == old.id ? saved : a).toList(),
    ));

    try {
      await AlarmFirestoreService.deleteAlarm(old.id);
      await AlarmFirestoreService.saveAlarm(saved);
    } catch (e) {
      // Rollback: cancel new native, re-schedule old, restore UI
      await AlarmChannel.cancel(newId);
      try {
        await _scheduleNative(old, old.dateTime);
      } catch (_) {}
      emit(state.copyWith(alarms: previousAlarms));
      rethrow;
    }
  }

  Future<void> removeAlarm(String id) async {
    final previousAlarms = state.alarms;

    await AlarmChannel.cancel(id);
    await AlarmChannel.cleanupConfig(id);

    // Optimistic
    emit(state.copyWith(
      alarms: state.alarms.where((a) => a.id != id).toList(),
    ));

    try {
      await AlarmFirestoreService.deleteAlarm(id);
    } catch (e) {
      // Rollback: re-schedule native and restore UI
      final alarm = previousAlarms.firstWhere((a) => a.id == id);
      try {
        await _scheduleNative(alarm, alarm.dateTime);
      } catch (_) {}
      emit(state.copyWith(alarms: previousAlarms));
      rethrow;
    }
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
