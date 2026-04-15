import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../missions/models/mission.dart';
import '../../wakeup/services/history_service.dart';
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
    await _markMissedAlarms();
  }

  /// Restores alarms from Firestore (source of truth) and reschedules any
  /// that are no longer registered in the native alarm system.
  Future<void> _syncAlarms() async {
    final results = await Future.wait([
      AlarmFirestoreService.getAlarms(),
      AlarmChannel.getAlarmIds(),
      AlarmChannel.getSnoozeMap(),
    ]);
    final firestoreAlarms = results[0] as List<AppAlarmEntry>;
    final nativeIds = (results[1] as List<String>).toSet();
    // {snoozeId → originalId} — snooze alarms are native-only, no Firestore doc.
    final snoozeMap = results[2] as Map<String, String>;
    final now = DateTime.now();
    final resolved = <AppAlarmEntry>[];

    // Check firestore alarms are planned
    for (final alarm in firestoreAlarms) {
      // Disabled or already scheduled natively — no action needed.
      if (!alarm.isEnabled || nativeIds.contains(alarm.id)) {
        resolved.add(alarm);
        continue;
      }

      // Alarm is enabled but missing from native — reschedule it.
      final isRecurrent = !alarm.isOneTime && alarm.repeatDays.any((d) => d);
      var scheduled = alarm.dateTime;
      final isPast = scheduled.isBefore(now);

      if (isPast && !isRecurrent) {
        // Unique alarm missed — ring now.
        scheduled = now.add(const Duration(seconds: 5));
      }
      // Recurrent: scheduleRepeating uses hour/minute as-is, no time shift needed.

      try {
        final newId = await _scheduleNative(alarm, scheduled);
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = alarm.copyWith(id: newId, dateTime: scheduled);
        await AlarmFirestoreService.saveAlarm(rescheduled);
        resolved.add(rescheduled);
      } catch (e) {
        debugPrint(
          '[AlarmCubit] _syncAlarms reschedule failed for ${alarm.id}: $e',
        );
        resolved.add(alarm);
      }
    }

    // Cancel orphaned native alarms not referenced by any Firestore entry.
    // Snooze alarms are intentionally native-only — skip them unless their
    // original alarm has been disabled, in which case cancel the snooze too.
    final resolvedIds = resolved.map((a) => a.id).toSet();
    for (final nativeId in nativeIds) {
      if (resolvedIds.contains(nativeId)) continue;

      final originalId = snoozeMap[nativeId];
      if (originalId != null) {
        final originalEnabled = resolved.any(
          (a) => a.id == originalId && a.isEnabled,
        );
        if (originalEnabled) continue; // valid active snooze — leave it alone
        // Original was disabled — cancel the orphaned snooze too
        debugPrint(
          '[AlarmCubit] cancelling snooze $nativeId (original $originalId disabled)',
        );
      } else {
        debugPrint('[AlarmCubit] cancelling orphaned native alarm $nativeId');
      }

      try {
        await AlarmChannel.cancel(nativeId);
        await AlarmChannel.cleanupConfig(nativeId);
      } catch (e) {
        debugPrint('[AlarmCubit] orphan cleanup failed for $nativeId: $e');
      }
    }

    emit(state.copyWith(alarms: resolved));
  }

  /// Creates missed sessions for enabled alarms that should have fired but
  /// have no session in Firebase. Handles both one-time and recurrent alarms.
  /// For recurrent alarms, checks each expected fire in the past 7 days.
  Future<void> _markMissedAlarms() async {
    try {
      final now = DateTime.now();
      final alarms = state.alarms;
      final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);

      final recentSessions = await HistoryService.getSessions(
        limit: 500,
        since: sevenDaysAgo,
        includeIncomplete: true,
      );

      for (final alarm in alarms) {
        if (!alarm.isEnabled) continue;

        // One-time alarm in the past with no session → missed.
        if (alarm.isOneTime) {
          if (!alarm.dateTime.isBefore(now)) continue;
          final hasSession = recentSessions.any((s) => s.alarmId == alarm.id);
          if (!hasSession) {
            await HistoryService.createMissedSession(
              alarmId: alarm.id,
              missionType: alarm.missionType,
              soundId: alarm.soundId,
              timestamp: alarm.dateTime,
            );
            debugPrint('[AlarmCubit] marked missed (one-time): ${alarm.id}');
          }
          continue;
        }

        // Recurrent alarm — check each expected fire in the past 7 days.
        final isRecurrent = alarm.repeatDays.any((d) => d);
        if (!isRecurrent) continue;

        // repeatDays: index 0=Sun, 1=Mon, 2=Tue, ..., 6=Sat
        // Dart weekday: 1=Mon, 2=Tue, ..., 7=Sun
        final hour = alarm.dateTime.hour;
        final minute = alarm.dateTime.minute;

        for (var day = sevenDaysAgo;
            day.isBefore(now);
            day = day.add(const Duration(days: 1))) {
          // Convert Dart weekday (1=Mon..7=Sun) to repeatDays index (0=Sun..6=Sat).
          final repeatIndex = day.weekday == 7 ? 0 : day.weekday;
          if (!alarm.repeatDays[repeatIndex]) continue;

          final expectedFire = DateTime(day.year, day.month, day.day, hour, minute);
          if (!expectedFire.isBefore(now)) continue;

          // Check if any session exists for this alarm on this day.
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          final hasSession = recentSessions.any((s) =>
              s.alarmId == alarm.id &&
              s.timestamp.isAfter(dayStart) &&
              s.timestamp.isBefore(dayEnd));
          if (hasSession) continue;

          await HistoryService.createMissedSession(
            alarmId: alarm.id,
            missionType: alarm.missionType,
            soundId: alarm.soundId,
            timestamp: expectedFire,
          );
          debugPrint(
            '[AlarmCubit] marked missed (recurrent): ${alarm.id} on ${expectedFire.toIso8601String()}',
          );
        }
      }
    } catch (e) {
      debugPrint('[AlarmCubit] _markMissedAlarms failed: $e');
    }
  }

  /// Returns [dt] unchanged if it's in the future, otherwise advances it by
  /// whole days until it lands tomorrow (same time of day) or later.
  DateTime _nextFutureDay(DateTime dt) {
    final now = DateTime.now();
    if (!dt.isBefore(now)) return dt;
    return dt.add(Duration(days: now.difference(dt).inDays + 1));
  }

  Future<void> addAlarm(AppAlarmEntry entry) async {
    var scheduled = kDebugMode
        ? DateTime.now().add(const Duration(seconds: 5))
        : _nextFutureDay(entry.dateTime);

    final id = await _scheduleNative(entry, scheduled);
    final saved = entry.copyWith(id: id, dateTime: scheduled);

    // Optimistic: show in UI immediately
    emit(state.copyWith(alarms: [...state.alarms, saved]));

    try {
      await AlarmFirestoreService.saveAlarm(saved);
    } catch (e) {
      // Rollback: remove from UI and cancel native
      emit(
        state.copyWith(alarms: state.alarms.where((a) => a.id != id).toList()),
      );
      await AlarmChannel.cancel(id);
      rethrow;
    }
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final alarm = state.alarms.firstWhere((a) => a.id == id);
    final previousAlarms = state.alarms;

    if (!enabled) {
      final disabledAlarm = alarm.copyWith(isEnabled: false);

      // Optimistic
      emit(
        state.copyWith(
          alarms: state.alarms
              .map((a) => a.id == id ? disabledAlarm : a)
              .toList(),
        ),
      );

      try {
        await AlarmFirestoreService.saveAlarm(disabledAlarm);
      } catch (e) {
        // Rollback: re-schedule native and restore UI
        emit(state.copyWith(alarms: previousAlarms));
        rethrow;
      }
      try {
        await AlarmChannel.cancel(id);
      } catch (e, stack) {
        debugPrint('[AlarmCubit] Failed to cancel alarm $id: $e\n$stack');
      }
 
    } else {
      final scheduled = _nextFutureDay(alarm.dateTime);
      final newId = await _scheduleNative(alarm, scheduled);
      final rescheduled = alarm.copyWith(
        id: newId,
        dateTime: scheduled,
        isEnabled: true,
      );

      // Optimistic
      emit(
        state.copyWith(
          alarms: state.alarms
              .map((a) => a.id == id ? rescheduled : a)
              .toList(),
        ),
      );

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

    final scheduled = kDebugMode
        ? DateTime.now().add(const Duration(seconds: 5))
        : _nextFutureDay(updated.dateTime);

    final newId = await _scheduleNative(updated, scheduled);
    final saved = updated.copyWith(id: newId, dateTime: scheduled);

    // Optimistic
    emit(
      state.copyWith(
        alarms: state.alarms.map((a) => a.id == old.id ? saved : a).toList(),
      ),
    );

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

    // Optimistic
    emit(
      state.copyWith(alarms: state.alarms.where((a) => a.id != id).toList()),
    );

    try {
      await AlarmFirestoreService.deleteAlarm(id);
    } catch (e) {
      debugPrint('Error deleting alarm with id $id: $e');
      emit(state.copyWith(alarms: previousAlarms));
      return;
    }

    try {
      await AlarmChannel.cancel(id);
      await AlarmChannel.cleanupConfig(id);
    } catch (e) {
      debugPrint('Error cancelling/cleaning up alarm with id $id: $e');
    }
  }

  /// Schedules a native alarm, choosing one-shot or recurrent based on the
  /// entry's [repeatDays] and [isOneTime]. Pass [forceOneShot] to override
  /// (e.g. in debug mode).
  Future<String> _scheduleNative(AppAlarmEntry entry, DateTime scheduled) {
    final info = missionInfoFor(entry.missionType);
    final title = entry.name.isNotEmpty ? entry.name : 'Levio';
    final sfSymbol = _systemImageFor(entry.missionType);
    final secondaryLabel = info.name;
    // soundId is the filename (without .mp3) under assets/sounds/
    final soundPath = entry.soundId != 'default'
        ? 'assets/sounds/${entry.soundId}.mp3'
        : null;

    final isRecurrent = !entry.isOneTime && entry.repeatDays.any((d) => d);

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
