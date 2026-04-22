import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../subscription/services/analytics_service.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/services/history_service.dart';
import '../data/sounds.dart';
import '../services/alarm_channel.dart';
import '../services/alarm_firestore_service.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

  /// Constructor-side init: only request native AlarmKit authorization.
  /// Firestore reconciliation lives in [sync] and is gated by access in
  /// AppGateWrapper.
  Future<void> _init() async {
    try {
      await AlarmChannel.requestAuthorization();
    } catch (e) {
      debugPrint('[AlarmCubit] requestAuthorization failed: $e');
    }
  }

  /// Debug: dumps native AlarmKit alarms and cross-references with Flutter state.
  Future<void> printActiveAlarms() async {
    final flutterAlarms = state.alarms;
    final nativeAlarms = await AlarmChannel.getAlarms();
    final nativeIds = nativeAlarms.map((a) => a['id'] as String).toSet();

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[AlarmCubit] Native AlarmKit alarms (${nativeAlarms.length}):');
    for (final native in nativeAlarms) {
      final id = native['id'] as String;
      debugPrint('  • $id');
      debugPrint('      state          : ${native['state']}');
      debugPrint('      title          : ${native['title'] ?? '-'}');
      debugPrint('      sfSymbol       : ${native['sfSymbol'] ?? '-'}');
      debugPrint('      secondaryLabel : ${native['secondaryLabel'] ?? '-'}');
      debugPrint('      isOneShot      : ${native['isOneShot']}');
      if (native['timestampMs'] != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          (native['timestampMs'] as double).toInt(),
        );
        debugPrint('      scheduledAt    : $dt');
      }
      if (native['weekdayMask'] != null) {
        debugPrint(
          '      weekdayMask    : ${native['weekdayMask']}  hour=${native['hour']}  minute=${native['minute']}',
        );
      }

      final match = flutterAlarms.where((a) => a.id == id).firstOrNull;
      if (match != null) {
        debugPrint(
          '      [Flutter] name       : ${match.name.isEmpty ? "(no name)" : match.name}',
        );
        debugPrint('      [Flutter] enabled    : ${match.isEnabled}');
        debugPrint(
          '      [Flutter] missions   : ${match.missions.map((m) => m.type.name).toList()}',
        );
        debugPrint('      [Flutter] sound      : ${match.soundId}');
        debugPrint('      [Flutter] repeatDays : ${match.repeatDays}');
      } else {
        debugPrint('      [Flutter] ⚠ not found in Flutter state');
      }
    }

    final orphans = flutterAlarms.where((a) => !nativeIds.contains(a.id));
    if (orphans.isNotEmpty) {
      debugPrint('[AlarmCubit] Flutter-only (not in AlarmKit):');
      for (final a in orphans) {
        debugPrint('  • ${a.id}  name=${a.name}  enabled=${a.isEnabled}');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Loads alarms from Firestore into state. Called on auth so the UI has
  /// data before the gated [sync] runs.
  Future<void> loadAlarm() async {
    try {
      final alarms = await AlarmFirestoreService.getAlarms();
      emit(state.copyWith(alarms: alarms));
    } catch (e) {
      debugPrint('[AlarmCubit] loadAlarm failed: $e');
    }
  }

  /// Restores alarms from Firestore (source of truth), reschedules missing
  /// native alarms, cancels orphans, and creates missed-session entries.
  /// Only call when the user has access to gated features.
  Future<void> sync() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true));
    try {
      await _reconcileWithNative();
      await _markMissedAlarms();
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _reconcileWithNative() async {
    final results = await Future.wait([
      AlarmFirestoreService.getAlarms(),
      AlarmChannel.getAlarmIds(),
    ]);
    final firestoreAlarms = results[0] as List<AppAlarmEntry>;
    final nativeIds = (results[1] as List<String>).toSet();
    final now = DateTime.now();
    final resolved = <AppAlarmEntry>[];

    for (final alarm in firestoreAlarms) {
      // Disabled alarm — if a cascade leaked (e.g. a prior toggle-off failed
      // mid-flight) cancel it now so it doesn't keep ringing. Without this,
      // the orphan-cancel loop below would skip it because its id is in
      // `resolvedIds`.
      if (!alarm.isEnabled) {
        if (nativeIds.contains(alarm.id)) {
          debugPrint('[AlarmCubit] cancelling leaked cascade for disabled ${alarm.id}');
          try {
            await AlarmChannel.cancel(alarm.id);
            await AlarmChannel.cleanupConfig(alarm.id);
          } catch (e) {
            debugPrint('[AlarmCubit] disabled-cleanup failed for ${alarm.id}: $e');
          }
        }
        resolved.add(alarm);
        continue;
      }

      // Enabled alarm already scheduled natively — no action needed.
      if (nativeIds.contains(alarm.id)) {
        resolved.add(alarm);
        continue;
      }

      // Alarm is enabled but has no active cascade — reschedule it.
      final isRecurrent = !alarm.isOneTime && alarm.repeatDays.any((d) => d);
      final isPast = alarm.dateTime.isBefore(now);

      // One-shot missed → ring now; recurrent uses hour/minute as-is.
      final toSchedule = (isPast && !isRecurrent)
          ? alarm.copyWith(dateTime: now.add(const Duration(seconds: 5)))
          : alarm;

      try {
        // Purge any stale native config under the old id. This is the common
        // case for recurrent alarms whose user slept through the full 6-min
        // cascade: the burst UUIDs are gone but `levio_config_` and
        // `levio_cascade_meta_` still linger in UserDefaults under `alarm.id`.
        try {
          await AlarmChannel.cleanupConfig(alarm.id);
        } catch (_) {}
        final newId = await _scheduleNative(toSchedule);
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = toSchedule.copyWith(id: newId);
        await AlarmFirestoreService.saveAlarm(rescheduled);
        resolved.add(rescheduled);
      } catch (e) {
        debugPrint('[AlarmCubit] sync reschedule failed for ${alarm.id}: $e');
        resolved.add(alarm);
      }
    }

    // Cancel orphaned native cascades not referenced by any Firestore entry.
    final resolvedIds = resolved.map((a) => a.id).toSet();
    for (final nativeId in nativeIds) {
      if (resolvedIds.contains(nativeId)) continue;
      debugPrint('[AlarmCubit] cancelling orphaned cascade $nativeId');
      try {
        await AlarmChannel.cancel(nativeId);
        await AlarmChannel.cleanupConfig(nativeId);
      } catch (e) {
        debugPrint('[AlarmCubit] orphan cleanup failed for $nativeId: $e');
      }
    }

    // Prime recurrent cascades whose `.relative` safety-net is alive but whose
    // `.fixed` bursts have all fired. The user ignored the full 6-min cascade
    // last week; now that the app is open, re-fill the bursts for next time
    // without touching the originalId or the recurring `.relative` burst.
    for (final alarm in resolved) {
      if (!alarm.isEnabled) continue;
      if (alarm.isOneTime) continue;
      if (!alarm.repeatDays.any((d) => d)) continue;
      try {
        await AlarmChannel.primeCascadeIfNeeded(alarm.id);
      } catch (e) {
        debugPrint('[AlarmCubit] primeCascadeIfNeeded failed for ${alarm.id}: $e');
      }
    }

    emit(state.copyWith(alarms: resolved));
  }

  /// Cancels every cascade and clears the in-memory list.
  /// Used on logout — does not touch Firestore (data stays scoped to that uid).
  Future<void> cancelAllNative() async {
    try {
      final nativeIds = await AlarmChannel.getAlarmIds();
      for (final id in nativeIds) {
        try {
          await AlarmChannel.cancel(id);
          await AlarmChannel.cleanupConfig(id);
        } catch (e) {
          debugPrint('[AlarmCubit] cancelAllNative failed for $id: $e');
        }
      }
    } catch (e) {
      debugPrint('[AlarmCubit] cancelAllNative getAlarmIds failed: $e');
    }
    emit(state.copyWith(alarms: const []));
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
            ? DateTime(
                alarm.createdAt.year,
                alarm.createdAt.month,
                alarm.createdAt.day,
              )
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

        for (
          var day = lookbackStart;
          day.isBefore(now);
          day = day.add(const Duration(days: 1))
        ) {
          final repeatIndex = day.weekday == 7 ? 0 : day.weekday;
          if (!alarm.repeatDays[repeatIndex]) continue;

          final expectedFire = DateTime(
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          );
          if (!expectedFire.isBefore(now)) continue;

          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          final hasSession = recentSessions.any(
            (s) =>
                s.alarmId == alarm.id &&
                s.timestamp.isAfter(dayStart) &&
                s.timestamp.isBefore(dayEnd),
          );
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

    final firstMission = saved.missions.isNotEmpty
        ? saved.missions.first.type.name
        : 'none';
    AnalyticsService.capture(AnalyticsService.alarmCreated, {
      'mission_type': firstMission,
      'mission_count': saved.missions.length,
      'is_one_time': saved.isOneTime,
      'repeats': saved.repeatDays.where((d) => d).length,
      'sound_id': saved.soundId,
    });
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
      final rescheduled = toSchedule.copyWith(
        id: newId,
        disabledBySubscription: false,
      );

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

    AnalyticsService.capture(AnalyticsService.alarmToggled, {
      'enabled': enabled,
    });
  }

  Future<void> editAlarm(AppAlarmEntry old, AppAlarmEntry updated) async {
    final previousAlarms = state.alarms;

    await AlarmChannel.cancel(old.id);
    await AlarmChannel.cleanupConfig(old.id);

    final toSchedule = updated.copyWith(
      dateTime: _nextFutureDay(updated.dateTime),
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

    AnalyticsService.capture(AnalyticsService.alarmUpdated);
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
      await AlarmChannel.cancel(id);
      await AlarmChannel.cleanupConfig(id);
    } catch (e) {
      debugPrint('Error cancelling/cleaning up alarm with id $id: $e');
    }

    AnalyticsService.capture(AnalyticsService.alarmDeleted, {'alarm_id': id});
    AnalyticsService.capture(AnalyticsService.alarmStopped, {'alarm_id': id});
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
      final disabled = alarm.copyWith(
        isEnabled: false,
        disabledBySubscription: true,
      );
      try {
        await AlarmFirestoreService.saveAlarm(disabled);
      } catch (e) {
        debugPrint(
          '[AlarmCubit] disableAllForSubscription save failed ${alarm.id}: $e',
        );
      }
      try {
        await AlarmChannel.cancel(alarm.id);
      } catch (e) {
        debugPrint(
          '[AlarmCubit] disableAllForSubscription cancel failed ${alarm.id}: $e',
        );
      }
    }
  }

  /// Re-enables alarms that were auto-disabled by a subscription lapse.
  Future<void> restoreSubscriptionDisabled() async {
    final toRestore = state.alarms
        .where((a) => a.disabledBySubscription)
        .toList();
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
          '[AlarmCubit] restoreSubscriptionDisabled failed ${alarm.id}: $e',
        );
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
