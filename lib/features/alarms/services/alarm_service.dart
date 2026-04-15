import 'dart:async';

import 'package:flutter/material.dart';
import '../../wakeup/services/history_service.dart';
import 'alarm_channel.dart';
import '../cubit/alarm_state.dart';
import 'alarm_firestore_service.dart';

class AlarmService {
  static StreamSubscription? _subscription;
  static AppLifecycleListener? _lifecycleListener;

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

  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    debugPrint(
      '[AlarmService] listenForRing: starting stream + lifecycle listener',
    );
    _subscription?.cancel();
    _subscription = AlarmChannel.events.listen(
      (event) async {
        final eventType = event['event'] as String?;
        debugPrint('[AlarmService] stream event: $event');

        if (eventType == 'ring') {
          final nativeAlarmId = event['id'] as String?;
          if (nativeAlarmId == null) return;

          final firestoreEntry = await _resolveEntry(nativeAlarmId);
          if (firestoreEntry == null) {
            debugPrint('[AlarmService] ring: alarm $nativeAlarmId not found');
            return;
          }

          final firstMission = firestoreEntry.missions.isNotEmpty
              ? firestoreEntry.missions.first
              : null;
          HistoryService.createPendingSession(
            alarmId: firestoreEntry.id,
            missionType: firstMission?.type,
            soundId: firestoreEntry.soundId,
          ).ignore();
          debugPrint(
            '[AlarmService] ring → pushing dismiss  nativeAlarmId=$nativeAlarmId originalAlarmId=${firestoreEntry.id}',
          );
          _pushDismiss(navigatorKey, _argsFrom(nativeAlarmId, firestoreEntry));
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
        final ringing = await getRingingAlarm();
        if (ringing == null) return;
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

  /// Fetches the Firestore entry for [alarmId], falling back to the snooze map
  /// if the ID belongs to a snooze (which has no Firestore doc of its own).
  static Future<AppAlarmEntry?> _resolveEntry(String alarmId) async {
    var entry = await AlarmFirestoreService.getAlarm(alarmId);
    if (entry == null) {
      final originalId = (await AlarmChannel.getSnoozeMap())[alarmId];
      if (originalId != null)
        entry = await AlarmFirestoreService.getAlarm(originalId);
    }
    return entry;
  }

  /// Only passes identifiers — mission config is fetched from Firestore at
  /// dismiss time.
  static Map<String, String> _argsFrom(
    String nativeAlarmId,
    AppAlarmEntry entry,
  ) => {
    'alarmId': entry.id,
    'nativeAlarmId': nativeAlarmId,
    'label': entry.name,
  };

  /// Resolves [id] to nav args, returning null if the alarm can't be found.
  static Future<Map<String, String>?> _toNavArgs(String id) async {
    final entry = await _resolveEntry(id);
    if (entry == null) {
      debugPrint('[AlarmService] → alarm $id not found in Firestore');
      return null;
    }
    return _argsFrom(id, entry);
  }

  static void _pushDismiss(
    GlobalKey<NavigatorState> navigatorKey,
    Map<String, String> args,
  ) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/alarm-dismiss',
      (route) => route.isFirst,
      arguments: args,
    );
  }
}
