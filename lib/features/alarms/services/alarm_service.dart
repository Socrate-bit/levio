import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../wakeup/services/history_service.dart';
import 'alarm_channel.dart';
import 'alarm_firestore_service.dart';

class AlarmService {
  static StreamSubscription? _subscription;
  static AppLifecycleListener? _lifecycleListener;

  static const _actionChannel = MethodChannel('levio/alarm-action');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns nav args map for the first currently-alerting alarm, or null.
  static Future<Map<String, String>?> getRingingAlarm() async {
    final id = await AlarmChannel.getRingingId();
    debugPrint('[AlarmService] getRingingAlarm: ringingId=$id');
    if (id == null) return null;

    // Try direct Firestore lookup
    var entry = await AlarmFirestoreService.getAlarm(id);

    // Fallback: if _syncAlarms hasn't run yet, the ringing alarm may have a
    // new native UUID (from StopAndRescheduleIntent) that Firestore doesn't
    // know about yet. Peek at pending reschedules to find the old ID.
    if (entry == null) {
      debugPrint('[AlarmService] → ringing alarm $id not in Firestore, checking pending reschedules');
      final reschedules = await AlarmChannel.peekPendingReschedules();
      final oldId = reschedules.entries
          .where((e) => e.value == id)
          .map((e) => e.key)
          .firstOrNull;
      if (oldId != null) {
        entry = await AlarmFirestoreService.getAlarm(oldId);
        debugPrint('[AlarmService] → found via reschedule oldId=$oldId  entry=${entry != null}');
      }
    }

    if (entry == null) {
      debugPrint('[AlarmService] → ringing alarm $id not found in Firestore');
      return null;
    }
    debugPrint('[AlarmService] → ringing alarm  id=$id  challenge=${entry.missionType.name}');
    return {
      'alarmId': id,
      'challenge': entry.missionType.name,
      'mathDifficulty': entry.mathDifficulty.name,
      'customObject': entry.customObject ?? '',
    };
  }

  static Future<void> checkAndNavigate(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    debugPrint('[AlarmService] checkAndNavigate called');

    if (!await _hasPendingDismiss()) {
      debugPrint('[AlarmService] checkAndNavigate → no pending dismiss, aborting');
      return;
    }
    await _clearPendingDismiss();

    final ringing = await getRingingAlarm();
    if (ringing == null) {
      debugPrint('[AlarmService] checkAndNavigate → pendingDismiss true but no ringing alarm');
      return;
    }

    debugPrint('[AlarmService] checkAndNavigate → navigating to /alarm-dismiss  args=$ringing');
    _pushDismiss(navigatorKey, ringing);
  }

  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    debugPrint('[AlarmService] listenForRing: starting stream + lifecycle listener');
    _subscription?.cancel();
    _subscription = AlarmChannel.events.listen((event) async {
      final eventType = event['event'] as String?;
      debugPrint('[AlarmService] stream event: $event');

      if (eventType == 'ring') {
        final alarmId = event['id'] as String?;
        if (alarmId == null) return;
        final entry = await AlarmFirestoreService.getAlarm(alarmId);
        if (entry == null) {
          debugPrint('[AlarmService] ring: alarm $alarmId not found in Firestore');
          return;
        }
        HistoryService.createPendingSession(
          alarmId: alarmId,
          missionType: entry.missionType,
          soundId: entry.soundId,
        ).ignore();
        debugPrint('[AlarmService] ring → pushing dismiss  alarmId=$alarmId  challenge=${entry.missionType.name}');
        _pushDismiss(navigatorKey, {
          'alarmId': alarmId,
          'challenge': entry.missionType.name,
          'mathDifficulty': entry.mathDifficulty.name,
          'customObject': entry.customObject ?? '',
        });
        return;
      }

      if (eventType == 'intentFired') {
        debugPrint('[AlarmService] intentFired → querying ringing alarm');
        final ringing = await getRingingAlarm();
        if (ringing != null) {
          debugPrint('[AlarmService] intentFired → pushing dismiss  args=$ringing');
          _pushDismiss(navigatorKey, ringing);
        } else {
          debugPrint('[AlarmService] intentFired → no ringing alarm found');
        }
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('[AlarmService] stream error: $e\n$st');
    });

    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        debugPrint('[AlarmService] lifecycle: onResume');
        checkAndNavigate(navigatorKey);
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

  static Future<bool> _hasPendingDismiss() async {
    try {
      final result = await _actionChannel.invokeMethod<bool>('hasPendingDismiss') ?? false;
      debugPrint('[AlarmService] _hasPendingDismiss → $result');
      return result;
    } catch (e) {
      debugPrint('[AlarmService] _hasPendingDismiss error: $e');
      return false;
    }
  }

  static Future<void> _clearPendingDismiss() async {
    try {
      await _actionChannel.invokeMethod('clearPendingDismiss');
    } catch (e) {
      debugPrint('[AlarmService] _clearPendingDismiss error: $e');
    }
  }

  static void _pushDismiss(
      GlobalKey<NavigatorState> navigatorKey, Map<String, String> args) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/alarm-dismiss',
      (route) => route.isFirst,
      arguments: args,
    );
  }
}
