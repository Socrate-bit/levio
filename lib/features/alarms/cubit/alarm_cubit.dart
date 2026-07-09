import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../subscription/services/analytics_service.dart';
import '../../missions/models/mission.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../wakeup/services/history_service.dart';
import '../data/sounds.dart';
import '../services/alarm_channel.dart';
import '../services/alarm_firestore_service.dart';
import '../services/notification_service.dart';
import 'alarm_state.dart';

/// Thrown when the user tries to deactivate/delete an alarm during its
/// unvalidated ring window.
class AlarmLockedException implements Exception {}

class AlarmCubit extends Cubit<AlarmState> {
  // AlarmKit authorization is requested contextually (right before the user
  // picks their alarm time in onboarding), not at launch. Firestore
  // reconciliation lives in [sync] and is gated by access in AppGateWrapper.
  AlarmCubit() : super(const AlarmState());

  // Re-entrancy guards. These methods reschedule alarms (create native cascade
  // + rotate the Firestore doc id) and only emit the cleared state after their
  // awaits complete. Without a synchronous guard, a caller that fires them on
  // every rebuild would re-enter mid-flight, read the same stale alarms, and
  // schedule duplicates. Set at entry, cleared in `finally`.
  bool _restoreInProgress = false;
  bool _disableInProgress = false;

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

  /// Debug: dumps every raw native AlarmKit alarm + per-cascade size & next
  /// burst fire time. Useful to spot orphaned bursts, cascade under-fill, or
  /// a master/burst mismatch that `printActiveAlarms` hides by grouping.
  Future<void> printRawAlarms() async {
    final raw = await AlarmChannel.getRawAlarms();
    final cascades = await AlarmChannel.getAlarms();

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[AlarmCubit] Raw AlarmKit alarms (${raw.length}):');
    for (final a in raw) {
      debugPrint('  • alarmId=${a['id']}  cascadeId=${a['originalId'] ?? '-'}');
    }

    debugPrint('[AlarmCubit] Cascades (${cascades.length}):');
    for (final c in cascades) {
      debugPrint('  • ${c['id']}');
      debugPrint('      state            : ${c['state']}');
      debugPrint('      masterId         : ${c['masterId'] ?? '-'}');
      debugPrint('      masterAlive      : ${c['masterAlive']}');
      debugPrint(
        '      cascadeSize      : ${c['cascadeSize']} (live=${c['liveCascadeSize']})',
      );
      if (c['nextBurstId'] != null) {
        final tsMs = (c['nextBurstTimestampMs'] as num?)?.toInt();
        final dt =
            tsMs != null ? DateTime.fromMillisecondsSinceEpoch(tsMs) : null;
        debugPrint(
          '      nextBurst        : ${c['nextBurstId']}  at=$dt  alerting=${c['nextBurstIsAlerting']}',
        );
      } else {
        debugPrint('      nextBurst        : -');
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
    } catch (e, st) {
      debugPrint('[AlarmCubit] loadAlarm failed: $e');
      AnalyticsService.trackError('AlarmCubit.loadAlarm', e, st);
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

    // Collapse strictly-identical duplicate docs (same content, different id)
    // that a prior reschedule race may have left behind. Two alarms are treated
    // as duplicates only when every field except `id`/`createdAt` matches — the
    // normalized entry is used as an Equatable-hashable key. Keep one per key,
    // preferring the copy already backed by a live native cascade, and
    // cancel + delete the rest so they stop ringing.
    AppAlarmEntry contentKey(AppAlarmEntry a) =>
        a.copyWith(id: '', createdAt: DateTime.fromMillisecondsSinceEpoch(0));
    final deduped = <AppAlarmEntry>[];
    final keptByKey = <AppAlarmEntry, AppAlarmEntry>{};
    for (final alarm in firestoreAlarms) {
      final key = contentKey(alarm);
      final kept = keptByKey[key];
      if (kept == null) {
        keptByKey[key] = alarm;
        deduped.add(alarm);
        continue;
      }
      // Duplicate: keep the one with a live cascade, drop the other.
      final replaceKept =
          nativeIds.contains(alarm.id) && !nativeIds.contains(kept.id);
      final winner = replaceKept ? alarm : kept;
      final loser = replaceKept ? kept : alarm;
      if (replaceKept) {
        keptByKey[key] = alarm;
        final idx = deduped.indexOf(kept);
        if (idx != -1) deduped[idx] = alarm;
      }
      debugPrint(
        '[AlarmCubit] collapsing duplicate alarm ${loser.id} (keeping ${winner.id})',
      );
      try {
        await AlarmChannel.cancel(loser.id);
        await AlarmChannel.cleanupConfig(loser.id);
        await AlarmFirestoreService.deleteAlarm(loser.id);
      } catch (e, st) {
        debugPrint('[AlarmCubit] duplicate cleanup failed for ${loser.id}: $e');
        AnalyticsService.trackError('AlarmCubit._reconcileWithNative.dedup', e, st);
      }
    }

    final resolved = <AppAlarmEntry>[];

    for (final alarm in deduped) {
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
          } catch (e, st) {
            debugPrint('[AlarmCubit] disabled-cleanup failed for ${alarm.id}: $e');
            AnalyticsService.trackError('AlarmCubit._reconcileWithNative.disabledCleanup', e, st);
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

      // One-shot missed → drop it.
      final toSchedule = alarm;
      
      if (isPast && !isRecurrent) {
        continue;
      }

      try {
        // Purge any stale native config under the old id. This is the common
        // case for recurrent alarms whose user slept through the full cascade:
        // the burst UUIDs are gone but `levio_config_` still lingers in
        // UserDefaults under `alarm.id`.
        try {
          await AlarmChannel.cleanupConfig(alarm.id);
        } catch (e, st) {
          AnalyticsService.trackError('AlarmCubit._reconcileWithNative.cleanupConfig', e, st);
        }
        final newId = await _scheduleNative(toSchedule);
        await AlarmFirestoreService.deleteAlarm(alarm.id);
        final rescheduled = toSchedule.copyWith(id: newId);
        await AlarmFirestoreService.saveAlarm(rescheduled);
        resolved.add(rescheduled);
      } catch (e, st) {
        debugPrint('[AlarmCubit] sync reschedule failed for ${alarm.id}: $e');
        AnalyticsService.trackError('AlarmCubit._reconcileWithNative.reschedule', e, st);
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
      } catch (e, st) {
        debugPrint('[AlarmCubit] orphan cleanup failed for $nativeId: $e');
        AnalyticsService.trackError('AlarmCubit._reconcileWithNative.orphanCleanup', e, st);
      }
    }

    // Prime recurrent cascades whose `.relative` safety-net is alive but whose
    // `.fixed` bursts have all fired. The user ignored the full 6-min cascade
    // last time; now that the app is open, re-fill the bursts for next time
    // without touching the originalId or the recurring `.relative` burst.
    for (final alarm in resolved) {
      if (!alarm.isEnabled) continue;
      if (alarm.isOneTime) continue;
      if (!alarm.repeatDays.any((d) => d)) continue;
      try {
        await AlarmChannel.primeCascadeIfNeeded(alarm.id);
      } catch (e, st) {
        debugPrint('[AlarmCubit] primeCascadeIfNeeded failed for ${alarm.id}: $e');
        AnalyticsService.trackError('AlarmCubit._reconcileWithNative.primeCascade', e, st);
      }
    }

    // Reconcile pre-alarm reminders for sleep alarms (best-effort, keyed to the
    // resolved ids so a sync-time reschedule moves the reminder too).
    for (final alarm in resolved) {
      NotificationService.syncReminder(alarm).ignore();
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
        } catch (e, st) {
          debugPrint('[AlarmCubit] cancelAllNative failed for $id: $e');
          AnalyticsService.trackError('AlarmCubit.cancelAllNative.cancel', e, st);
        }
      }
    } catch (e, st) {
      debugPrint('[AlarmCubit] cancelAllNative getAlarmIds failed: $e');
      AnalyticsService.trackError('AlarmCubit.cancelAllNative.getAlarmIds', e, st);
    }
    emit(state.copyWith(alarms: const []));
  }

  /// Grace period after an expected fire before it can be marked missed. Keeps
  /// the startup sync from racing the ring/dismiss flow (which would create a
  /// missed twin of the session the dismiss flow is about to complete).
  static const _missedGrace = Duration(minutes: 30);

  /// Creates missed sessions for enabled alarms that should have fired but
  /// have no session in Firebase.
  Future<void> _markMissedAlarms() async {
    try {
      final now = DateTime.now();
      final missedCutoff = now.subtract(_missedGrace);
      final alarms = state.alarms;
      final sevenDaysAgo = DateTime(now.year, now.month, now.day - 7);

      // Include auto-dismissed sessions: those alarms did fire, so they must
      // not be re-recorded as missed.
      final recentSessions = await HistoryService.getSessions(
        limit: 500,
        since: sevenDaysAgo,
        includeIncomplete: true,
        includeAutoDismissed: true,
      );

      // Alarms ringing right now are owned by the ring/dismiss flow — never
      // mark them missed (handles cascades that ring past the grace window).
      Set<String> ringingIds = const {};
      try {
        ringingIds = (await AlarmChannel.getRingingIds()).toSet();
      } catch (e) {
        debugPrint('[AlarmCubit] _markMissedAlarms getRingingIds failed: $e');
      }

      for (final alarm in alarms) {
        if (!alarm.isEnabled) continue;
        if (ringingIds.contains(alarm.id)) continue;
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
          if (!alarm.dateTime.isBefore(missedCutoff)) continue;
          if (alarm.dateTime.isBefore(alarm.createdAt)) continue;
          if (alarm.dateTime.isBefore(lookbackStart)) continue;
          final hasSession = recentSessions.any((s) => s.alarmId == alarm.id);
          if (!hasSession) {
            await HistoryService.createMissedSession(
              alarmId: alarm.id,
              missionType: missionType,
              soundId: alarm.soundId,
              timestamp: alarm.dateTime,
              isSleep: alarm.isSleep,
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
          // Past the grace window, and only for fires after the alarm existed.
          if (!expectedFire.isBefore(missedCutoff)) continue;
          if (expectedFire.isBefore(alarm.createdAt)) continue;

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
            isSleep: alarm.isSleep,
          );
          debugPrint(
            '[AlarmCubit] marked missed (recurrent): ${alarm.id} on ${expectedFire.toIso8601String()}',
          );
        }
      }
    } catch (e, st) {
      debugPrint('[AlarmCubit] _markMissedAlarms failed: $e');
      AnalyticsService.trackError('AlarmCubit._markMissedAlarms', e, st);
    }
  }

  DateTime _nextFutureDay(DateTime dt) {
    final now = DateTime.now();
    if (!dt.isBefore(now)) return dt;
    return dt.add(Duration(days: now.difference(dt).inDays + 1));
  }

  /// Clears spinToWin from every alarm except [excludeId]. Called whenever an
  /// alarm with spinToWin=true is saved to enforce the one-per-user constraint.
  Future<void> _clearSpinToWinExcept(String excludeId) async {
    final toClear = state.alarms
        .where((a) => a.id != excludeId && a.spinToWin)
        .toList();
    if (toClear.isEmpty) return;

    emit(state.copyWith(
      alarms: state.alarms.map((a) {
        if (a.id == excludeId || !a.spinToWin) return a;
        return a.copyWith(spinToWin: false);
      }).toList(),
    ));

    for (final alarm in toClear) {
      try {
        await AlarmFirestoreService.saveAlarm(alarm.copyWith(spinToWin: false));
      } catch (e, st) {
        debugPrint('[AlarmCubit] Failed to clear spinToWin on ${alarm.id}: $e');
        AnalyticsService.trackError('AlarmCubit._clearSpinToWinExcept', e, st);
      }
    }
  }

  Future<void> addAlarm(AppAlarmEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final forceQuick = prefs.getBool(SettingsCubit.forceQuickAlarmKey) ?? false;
    final toSchedule = entry.copyWith(
      isOneTime: forceQuick,
      dateTime: forceQuick
          ? DateTime.now().add(const Duration(seconds: 5))
          : _nextFutureDay(entry.dateTime),
    );

    // Schedule natively. If AlarmKit fails, still persist to Firestore under a
    // local id but mark it disabled so the UI shows it as inactive; the user
    // can re-enable to retry scheduling.
    String id;
    var scheduled = true;
    try {
      id = await _scheduleNative(toSchedule);
    } catch (e, st) {
      debugPrint(
        '[AlarmCubit] addAlarm native schedule failed, saving as disabled: $e',
      );
      AnalyticsService.trackError('AlarmCubit.addAlarm.scheduleNative', e, st);
      id = const Uuid().v4();
      scheduled = false;
    }
    final saved = toSchedule.copyWith(id: id, isEnabled: scheduled);

    // Optimistic: show in UI immediately
    emit(state.copyWith(alarms: [...state.alarms, saved]));

    try {
      await AlarmFirestoreService.saveAlarm(saved);
    } catch (e, st) {
      AnalyticsService.trackError('AlarmCubit.addAlarm', e, st);
      emit(
        state.copyWith(alarms: state.alarms.where((a) => a.id != id).toList()),
      );
      await AlarmChannel.cancel(id);
      rethrow;
    }

    // Best-effort pre-alarm reminder for sleep alarms.
    NotificationService.syncReminder(saved).ignore();

    final firstConfig =
        saved.missions.isNotEmpty ? saved.missions.first : null;
    AnalyticsService.capture(AnalyticsService.alarmCreated, {
      'mission_type': firstConfig?.type.name ?? 'none',
      'mission_count': saved.missions.length,
      'is_one_time': saved.isOneTime,
      'repeats': saved.repeatDays.where((d) => d).length,
      'sound_id': saved.soundId,
      // Picked objects + per-mission settings of the configured mission.
      if (firstConfig?.repCount != null) 'rep_count': firstConfig!.repCount!,
      if (firstConfig?.mathDifficulty != null)
        'math_difficulty': firstConfig!.mathDifficulty!.name,
      if (firstConfig?.mathProblemCount != null)
        'math_problem_count': firstConfig!.mathProblemCount!,
      if (firstConfig?.selectedItems != null)
        'selected_items': firstConfig!.selectedItems!,
      if (firstConfig?.selectedAffirmations != null)
        'selected_affirmations': firstConfig!.selectedAffirmations!,
      if (firstConfig?.affirmationCount != null)
        'affirmation_count': firstConfig!.affirmationCount!,
      if (firstConfig?.randomPool != null)
        'random_pool': firstConfig!.randomPool!.map((t) => t.name).toList(),
    });

    if (saved.spinToWin) await _clearSpinToWinExcept(saved.id);
  }

  /// True when [alarm] is within its ring window and that ring has not yet been
  /// validated by a completed session — deactivation/deletion must be blocked.
  Future<bool> _isRingLocked(AppAlarmEntry alarm) async {
    final start = alarm.activeRingStart(DateTime.now());
    if (start == null) return false;
    return !await HistoryService.hasValidatedRing(alarm.id, start);
  }

  Future<void> toggleAlarm(String id, bool enabled, {bool force = false}) async {
    final alarm = state.alarms.firstWhere((a) => a.id == id);
    final previousAlarms = state.alarms;

    if (!enabled) {
      // Block turning off an alarm mid-ring until the mission is completed.
      if (!force && await _isRingLocked(alarm)) throw AlarmLockedException();

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
      } catch (e, st) {
        AnalyticsService.trackError('AlarmCubit.toggleAlarm.disable', e, st);
        emit(state.copyWith(alarms: previousAlarms));
        rethrow;
      }
      try {
        await AlarmChannel.cancel(id);
      } catch (e, stack) {
        debugPrint('[AlarmCubit] Failed to cancel alarm $id: $e\n$stack');
        AnalyticsService.trackError('AlarmCubit.toggleAlarm.cancel', e, stack);
      }
      // Disabled alarm — drop any pending reminder.
      NotificationService.cancelReminder(id).ignore();
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
      } catch (e, st) {
        AnalyticsService.trackError('AlarmCubit.toggleAlarm.enable', e, st);
        await AlarmChannel.cancel(newId);
        emit(state.copyWith(alarms: previousAlarms));
        rethrow;
      }
      // Re-enabled under a new id — move the reminder across.
      NotificationService.cancelReminder(id).ignore();
      NotificationService.syncReminder(rescheduled).ignore();
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
    } catch (e, st) {
      AnalyticsService.trackError('AlarmCubit.editAlarm', e, st);
      await AlarmChannel.cancel(newId);
      try {
        await _scheduleNative(old);
      } catch (e2, st2) {
        AnalyticsService.trackError('AlarmCubit.editAlarm.rollbackReschedule', e2, st2);
      }
      emit(state.copyWith(alarms: previousAlarms));
      rethrow;
    }

    // Reminder follows the new id (the doc was re-created with newId).
    NotificationService.cancelReminder(old.id).ignore();
    NotificationService.syncReminder(saved).ignore();

    AnalyticsService.capture(AnalyticsService.alarmUpdated);

    if (saved.spinToWin) await _clearSpinToWinExcept(saved.id);
  }

  Future<void> removeAlarm(String id, {bool force = false}) async {
    final previousAlarms = state.alarms;

    // Block deleting an alarm mid-ring until the mission is completed.
    final alarm = state.alarms.firstWhere((a) => a.id == id);
    if (!force && await _isRingLocked(alarm)) throw AlarmLockedException();

    emit(
      state.copyWith(alarms: state.alarms.where((a) => a.id != id).toList()),
    );

    try {
      await AlarmFirestoreService.deleteAlarm(id);
    } catch (e, st) {
      debugPrint('Error deleting alarm with id $id: $e');
      AnalyticsService.trackError('AlarmCubit.removeAlarm.delete', e, st);
      emit(state.copyWith(alarms: previousAlarms));
      return;
    }

    try {
      await AlarmChannel.cancel(id);
      await AlarmChannel.cleanupConfig(id);
    } catch (e, st) {
      debugPrint('Error cancelling/cleaning up alarm with id $id: $e');
      AnalyticsService.trackError('AlarmCubit.removeAlarm.cancel', e, st);
    }

    NotificationService.cancelReminder(id).ignore();

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

    // Gentle sleep alarms fire a single alert with no burst cascade.
    final burstCount = entry.gentle ? 0 : AlarmChannel.defaultBurstCount;

    if (isRecurrent) {
      return AlarmChannel.scheduleRepeating(
        weekdayMask: AlarmChannel.toWeekdayMask(entry.repeatDays),
        hour: entry.dateTime.hour,
        minute: entry.dateTime.minute,
        title: title,
        sfSymbol: sfSymbol,
        secondaryLabel: secondaryLabel,
        soundPath: soundPath,
        burstCount: burstCount,
      );
    } else {
      return AlarmChannel.scheduleOneShot(
        timestampMs: entry.dateTime.millisecondsSinceEpoch,
        title: title,
        sfSymbol: sfSymbol,
        secondaryLabel: secondaryLabel,
        soundPath: soundPath,
        burstCount: burstCount,
      );
    }
  }

  /// Disables all enabled alarms because the user lost their subscription.
  Future<void> disableAllForSubscription() async {
    if (_disableInProgress) return;
    final enabledAlarms = state.alarms.where((a) => a.isEnabled).toList();
    if (enabledAlarms.isEmpty) return;
    _disableInProgress = true;
    try {
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
        } catch (e, st) {
          debugPrint(
            '[AlarmCubit] disableAllForSubscription save failed ${alarm.id}: $e',
          );
          AnalyticsService.trackError('AlarmCubit.disableAllForSubscription.save', e, st);
        }
        try {
          await AlarmChannel.cancel(alarm.id);
        } catch (e, st) {
          debugPrint(
            '[AlarmCubit] disableAllForSubscription cancel failed ${alarm.id}: $e',
          );
          AnalyticsService.trackError('AlarmCubit.disableAllForSubscription.cancel', e, st);
        }
      }
    } finally {
      _disableInProgress = false;
    }
  }

  /// Re-enables alarms that were auto-disabled by a subscription lapse.
  Future<void> restoreSubscriptionDisabled() async {
    if (_restoreInProgress) return;
    final toRestore = state.alarms
        .where((a) => a.disabledBySubscription)
        .toList();
    if (toRestore.isEmpty) return;
    _restoreInProgress = true;
    try {
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
        } catch (e, st) {
          debugPrint(
            '[AlarmCubit] restoreSubscriptionDisabled failed ${alarm.id}: $e',
          );
          AnalyticsService.trackError('AlarmCubit.restoreSubscriptionDisabled', e, st);
        }
      }

      emit(state.copyWith(alarms: updatedAlarms));
    } finally {
      _restoreInProgress = false;
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
      case MissionType.bedPhoto:
      case MissionType.objectHunt:
      case MissionType.petHunt:
      case MissionType.natureHunt:
      case MissionType.touchGrass:
        return 'camera.fill';
      case MissionType.affirmation:
        return 'mic.fill';
      case MissionType.breathing:
        return 'wind';
      case MissionType.gratefulness:
        return 'heart.fill';
      case MissionType.meditation:
        return 'figure.mind.and.body';
      case MissionType.math:
        return 'function';
      case MissionType.routine:
        return 'checklist';
      case MissionType.flappyBird:
        return 'gamecontroller.fill';
      case MissionType.random:
        return 'dice.fill';
    }
  }
}
