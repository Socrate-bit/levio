import 'dart:async';

import 'package:flutter/material.dart';
import '../../wakeup/services/history_service.dart';
import 'alarm_channel.dart';
import '../cubit/alarm_state.dart';
import 'alarm_firestore_service.dart';

class AlarmService {
  static StreamSubscription? _subscription;
  static AppLifecycleListener? _lifecycleListener;
  static bool _dismissScreenActive = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns nav args map for the first currently-alerting alarm, or null.
  static Future<Map<String, String>?> getRingingAlarm() async {
    final id = await AlarmChannel.getRingingId();
    debugPrint('[AlarmService] getRingingAlarm: ringingId=$id');
    if (id == null) return null;
    return _toNavArgs(id);
  }

  /// Listens for native ring events and pushes the dismiss screen.
  ///
  /// [canDismiss] — synchronous check called before showing dismiss. If it
  /// returns `false` the alarm is stopped and [onRingBlocked] is called.
  static void listenForRing(
    GlobalKey<NavigatorState> navigatorKey, {
    bool Function()? canDismiss,
    VoidCallback? onRingBlocked,
  }) {
    debugPrint(
      '[AlarmService] listenForRing: starting stream + lifecycle listener',
    );
    _subscription?.cancel();
    _subscription = AlarmChannel.events.listen(
      (event) async {
        final eventType = event['event'] as String?;
        debugPrint('[AlarmService] stream event: $event');

        if (eventType == 'ring') {
          if (_dismissScreenActive) return;

          // Ring events carry the burst id (`id`) and the logical cascade id
          // (`originalId`). Prefer originalId for Firestore lookup.
          final burstId = event['id'] as String?;
          final originalId = (event['originalId'] as String?) ?? burstId;
          if (originalId == null) return;

          // If the relative safety-net just rang with no .fixed bursts behind
          // it (user ignored last week's cascade), plan bursts now so the user
          // still gets the full 6-min pressure. No-op in every other case.
          AlarmChannel.primeCascadeIfNeeded(originalId).ignore();

          final firestoreEntry = await AlarmFirestoreService.getAlarm(originalId);
          if (firestoreEntry == null) {
            debugPrint('[AlarmService] ring: alarm $originalId not found — cancelling cascade');
            AlarmChannel.cancel(originalId).ignore();
            return;
          }

          // Gate: check if dismiss is allowed
          if (canDismiss != null && !canDismiss()) {
            debugPrint('[AlarmService] ring blocked — cancelling cascade $originalId');
            await AlarmChannel.cancel(originalId);
            onRingBlocked?.call();
            return;
          }

          _dismissScreenActive = true;

          final firstMission = firestoreEntry.missions.isNotEmpty
              ? firestoreEntry.missions.first
              : null;
          HistoryService.createPendingSession(
            alarmId: firestoreEntry.id,
            missionType: firstMission?.type,
            soundId: firestoreEntry.soundId,
          ).ignore();
          debugPrint(
            '[AlarmService] ring → pushing dismiss  burstId=$burstId originalId=$originalId',
          );
          _pushDismiss(
            navigatorKey,
            _argsFrom(burstId ?? originalId, firestoreEntry),
          );
          return;
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[AlarmService] stream error: $e\n$st');
      },
    );

    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () async {
        debugPrint('[AlarmService] lifecycle: onResume');
        if (_dismissScreenActive) return;

        final ringing = await getRingingAlarm();
        if (ringing == null) return;

        // Gate: check if dismiss is allowed on resume
        if (canDismiss != null && !canDismiss()) {
          final alarmId = ringing['alarmId']!;
          debugPrint('[AlarmService] resume ring blocked — cancelling cascade $alarmId');
          await AlarmChannel.cancel(alarmId);
          onRingBlocked?.call();
          return;
        }

        _pushDismiss(navigatorKey, ringing);
      },
      onHide: () => debugPrint('[AlarmService] lifecycle: onHide'),
      onShow: () => debugPrint('[AlarmService] lifecycle: onShow'),
      onInactive: () => debugPrint('[AlarmService] lifecycle: onInactive'),
      onPause: () => debugPrint('[AlarmService] lifecycle: onPause'),
      onDetach: () => debugPrint('[AlarmService] lifecycle: onDetach'),
      onRestart: () => debugPrint('[AlarmService] lifecycle: onRestart'),
    );
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Only passes identifiers — mission config is fetched from Firestore at
  /// dismiss time. `id` here is the originalId / alarmId.
  static Map<String, String> _argsFrom(
    String nativeAlarmId,
    AppAlarmEntry entry,
  ) => {
    'alarmId': entry.id,
    'nativeAlarmId': nativeAlarmId,
    'label': entry.name,
  };

  /// Resolves [originalId] to nav args, returning null if the alarm can't be found.
  static Future<Map<String, String>?> _toNavArgs(String originalId) async {
    final entry = await AlarmFirestoreService.getAlarm(originalId);
    if (entry == null) {
      debugPrint('[AlarmService] → alarm $originalId not found in Firestore — cancelling cascade');
      AlarmChannel.cancel(originalId).ignore();
      return null;
    }
    return _argsFrom(originalId, entry);
  }

  static void _pushDismiss(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, String> args,
  ) {
    _dismissScreenActive = true;
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(
          '/alarm-dismiss',
          (route) => route.isFirst,
          arguments: args,
        )
        .then((_) => _dismissScreenActive = false)
        .catchError((_) => _dismissScreenActive = false);
  }
}
