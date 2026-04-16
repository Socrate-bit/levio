import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../wakeup/services/history_service.dart';
import '../data/sounds.dart';
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
      final isPast = alarm.dateTime.isBefore(now);

      // One-shot missed → ring now; recurrent uses hour/minute as-is.
      final toSchedule = (isPast && !isRecurrent)
          ? alarm.copyWith(dateTime: now.add(const Duration(seconds: 5)))
          : alarm;

      try {
        final newId = await _scheduleNative(toSchedule);
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = toSchedule.copyWith(id: newId);
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
    final resolvedIds = resolved.map((a) => a.id).toSet();
    for (final nativeId in nativeIds) {
      if (resolvedIds.contains(nativeId)) continue;

      final originalId = snoozeMap[nativeId];
      if (originalId != null) {
        final originalEnabled = resolved.any(
          (a) => a.id == originalId && a.isEnabled,
        );
        if (originalEnabled) continue;
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
  /// have no session in Firebase.
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
        final missionType = alarm.missions.isNotEmpty
            ? alarm.missions.first.type
            : null;

        // Don't look back further than the alarm's creation date.
        final lookbackStart = alarm.createdAt.isAfter(sevenDaysAgo)
            ? DateTime(alarm.createdAt.year, alarm.createdAt.month,
                alarm.createdAt.day)
            : sevenDaysAgo;

        // One-time alarm in the past with no session → missed.
        if (alarm.isOneTime) {
          if (!alarm.dateTime.isBefore(now)) continue;
          if (alarm.dateTime.isBefore(lookbackStart)) continue;
          final hasSession = recentSessions.any((s) => s.alarmId == alarm.id);
          if (!hasSession) {
            await HistoryService.createMissedSession(
              alarmId: alarm.id,
              missionType: missionType,
              soundId: alarm.soundId,
              timestamp: alarm.dateTime,
            );
            debugPrint('[AlarmCubit] marked missed (one-time): ${alarm.id}');
          }
          continue;
        }

        // Recurrent alarm — check each expected fire since lookbackStart.
        final isRecurrent = alarm.repeatDays.any((d) => d);
        if (!isRecurrent) continue;

        final hour = alarm.dateTime.hour;
        final minute = alarm.dateTime.minute;

        for (var day = lookbackStart;
            day.isBefore(now);
            day = day.add(const Duration(days: 1))) {
          final repeatIndex = day.weekday == 7 ? 0 : day.weekday;
          if (!alarm.repeatDays[repeatIndex]) continue;

          final expectedFire = DateTime(day.year, day.month, day.day, hour, minute);
          if (!expectedFire.isBefore(now)) continue;

          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          final hasSession = recentSessions.any((s) =>
              s.alarmId == alarm.id &&
              s.timestamp.isAfter(dayStart) &&
              s.timestamp.isBefore(dayEnd));
          if (hasSession) continue;

          await HistoryService.createMissedSession(
            alarmId: alarm.id,
            missionType: missionType,
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

  DateTime _nextFutureDay(DateTime dt) {
    final now = DateTime.now();
    if (!dt.isBefore(now)) return dt;
    return dt.add(Duration(days: now.difference(dt).inDays + 1));
  }

  Future<void> addAlarm(AppAlarmEntry entry) async {
    final toSchedule = entry.copyWith(
      dateTime: kDebugMode
          ? DateTime.now().add(const Duration(seconds: 10))
          : _nextFutureDay(entry.dateTime),
    );

    final id = await _scheduleNative(toSchedule);
    final saved = toSchedule.copyWith(id: id);

    // Optimistic: show in UI immediately
    emit(state.copyWith(alarms: [...state.alarms, saved]));

    try {
      await AlarmFirestoreService.saveAlarm(saved);
    } catch (e) {
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
        emit(state.copyWith(alarms: previousAlarms));
        rethrow;
      }
      try {
        await AlarmChannel.cancel(id);
      } catch (e, stack) {
        debugPrint('[AlarmCubit] Failed to cancel alarm $id: $e\n$stack');
      }
    } else {
      final now = DateTime.now();
      final toSchedule = alarm.copyWith(
        dateTime: _nextFutureDay(alarm.dateTime),
        isEnabled: true,
        createdAt: now,
      );
      final newId = await _scheduleNative(toSchedule);
      final rescheduled =
          toSchedule.copyWith(id: newId, disabledBySubscription: false);

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

    final toSchedule = updated.copyWith(
      dateTime: kDebugMode
          ? DateTime.now().add(const Duration(seconds: 5))
          : _nextFutureDay(updated.dateTime),
    );

    final newId = await _scheduleNative(toSchedule);
    final saved = toSchedule.copyWith(id: newId);

    emit(
      state.copyWith(
        alarms: state.alarms.map((a) => a.id == old.id ? saved : a).toList(),
      ),
    );

    try {
      await AlarmFirestoreService.deleteAlarm(old.id);
      await AlarmFirestoreService.saveAlarm(saved);
    } catch (e) {
      await AlarmChannel.cancel(newId);
      try {
        await _scheduleNative(old);
      } catch (_) {}
      emit(state.copyWith(alarms: previousAlarms));
      rethrow;
    }
  }

  Future<void> removeAlarm(String id) async {
    final previousAlarms = state.alarms;

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
      await AlarmChannel.cancelSnoozesForAlarm(id);
      await AlarmChannel.cancel(id);
      await AlarmChannel.cleanupConfig(id);
    } catch (e) {
      debugPrint('Error cancelling/cleaning up alarm with id $id: $e');
    }
  }

  /// Schedules a native alarm, choosing one-shot or recurrent based on the
  /// entry's [repeatDays] and [isOneTime]. Uses entry.dateTime directly.
  Future<String> _scheduleNative(AppAlarmEntry entry) async {
    final title = entry.name.isNotEmpty ? entry.name : 'Levio';
    final firstType = entry.missions.isNotEmpty
        ? entry.missions.first.type
        : MissionType.none;
    final sfSymbol = _systemImageFor(firstType);

    final String secondaryLabel;
    if (entry.missions.isEmpty) {
      secondaryLabel = 'Alarm';
    } else if (entry.missions.length == 1) {
      secondaryLabel = missionInfoFor(firstType).name;
    } else {
      secondaryLabel = '${entry.missions.length} Missions';
    }

    // Resolve sound path: custom sounds use absolute file path, presets use asset path
    String? soundPath;
    if (entry.soundId == 'default') {
      soundPath = null;
    } else if (isCustomSound(entry.soundId)) {
      final customs = await loadCustomSounds();
      final custom = customs.where((s) => s.id == entry.soundId).firstOrNull;
      if (custom != null) {
        soundPath = await customSoundFilePath(custom.fileName);
      }
    } else {
      final resolved = soundAssetPath(entry.soundId);
      soundPath = resolved != null ? 'assets/$resolved' : null;
    }

    final isRecurrent = !entry.isOneTime && entry.repeatDays.any((d) => d);

    if (isRecurrent) {
      return AlarmChannel.scheduleRepeating(
        weekdayMask: AlarmChannel.toWeekdayMask(entry.repeatDays),
        hour: entry.dateTime.hour,
        minute: entry.dateTime.minute,
        title: title,
        sfSymbol: sfSymbol,
        secondaryLabel: secondaryLabel,
        soundPath: soundPath,
      );
    } else {
      return AlarmChannel.scheduleOneShot(
        timestampMs: entry.dateTime.millisecondsSinceEpoch,
        title: title,
        sfSymbol: sfSymbol,
        secondaryLabel: secondaryLabel,
        soundPath: soundPath,
      );
    }
  }

  /// Disables all enabled alarms because the user lost their subscription.
  Future<void> disableAllForSubscription() async {
    final enabledAlarms = state.alarms.where((a) => a.isEnabled).toList();
    if (enabledAlarms.isEmpty) return;

    // Optimistic: mark all as disabled in one emit
    final updated = state.alarms.map((a) {
      if (!a.isEnabled) return a;
      return a.copyWith(isEnabled: false, disabledBySubscription: true);
    }).toList();
    emit(state.copyWith(alarms: updated));

    for (final alarm in enabledAlarms) {
      final disabled =
          alarm.copyWith(isEnabled: false, disabledBySubscription: true);
      try {
        await AlarmFirestoreService.saveAlarm(disabled);
      } catch (e) {
        debugPrint(
            '[AlarmCubit] disableAllForSubscription save failed ${alarm.id}: $e');
      }
      try {
        await AlarmChannel.cancel(alarm.id);
      } catch (e) {
        debugPrint(
            '[AlarmCubit] disableAllForSubscription cancel failed ${alarm.id}: $e');
      }
    }
  }

  /// Re-enables alarms that were auto-disabled by a subscription lapse.
  Future<void> restoreSubscriptionDisabled() async {
    final toRestore =
        state.alarms.where((a) => a.disabledBySubscription).toList();
    if (toRestore.isEmpty) return;

    final updatedAlarms = List<AppAlarmEntry>.from(state.alarms);

    for (final alarm in toRestore) {
      try {
        final toSchedule = alarm.copyWith(
          dateTime: _nextFutureDay(alarm.dateTime),
          isEnabled: true,
          disabledBySubscription: false,
          createdAt: DateTime.now(),
        );
        final newId = await _scheduleNative(toSchedule);
        final rescheduled = toSchedule.copyWith(id: newId);

        final idx = updatedAlarms.indexWhere((a) => a.id == alarm.id);
        if (idx != -1) updatedAlarms[idx] = rescheduled;

        await AlarmFirestoreService.deleteAlarm(alarm.id);
        await AlarmFirestoreService.saveAlarm(rescheduled);
      } catch (e) {
        debugPrint(
            '[AlarmCubit] restoreSubscriptionDisabled failed ${alarm.id}: $e');
      }
    }

    emit(state.copyWith(alarms: updatedAlarms));
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
      case MissionType.affirmation:
        return 'mic.fill';
      case MissionType.math:
        return 'function';
      case MissionType.random:
        return 'dice.fill';
    }
  }
}
