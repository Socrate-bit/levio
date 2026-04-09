import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

class AlarmService {
  static StreamSubscription? _subscription;
  static AppLifecycleListener? _lifecycleListener;

  static const _actionChannel = MethodChannel('levio/alarm-action');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the ID of the first currently-alerting (or snoozed) alarm, if any.
  ///
  /// AlarmKit maps both the alerting and snoozed states to the @unknown default
  /// branch in Alarm+Extension.swift, so both appear as state == "unknown" here.
  static Future<String?> getRingingAlarm() async {
    final plugin = FlutterAlarmkit();
    final alarms = await plugin.getAlarms();
    for (final alarm in alarms) {
      final state = alarm['state'] as String?;
      if (state == 'unknown') return alarm['id'] as String?;
    }
    return null;
  }

  /// `true` when the user tapped a notification action while the app was killed.
  /// Written by AppDelegate → UserDefaults; read here on cold start / resume.
  static Future<bool> _hasPendingDismiss() async {
    try {
      return await _actionChannel.invokeMethod<bool>('hasPendingDismiss') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _clearPendingDismiss() async {
    try {
      await _actionChannel.invokeMethod('clearPendingDismiss');
    } catch (_) {}
  }

  /// Navigates to /alarm-dismiss when a pending UserDefaults flag exists AND
  /// AlarmKit still has a snoozed alarm to dismiss.  Safe to call at any time.
  static Future<void> checkAndNavigate(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (!await _hasPendingDismiss()) return;
    await _clearPendingDismiss();

    // The alarm is snoozed → still returned by getRingingAlarm().
    final alarmId = await getRingingAlarm();
    if (alarmId == null) return;

    _pushDismiss(navigatorKey, alarmId);
  }

  /// Starts the alarm-update stream listener and an AppLifecycleListener.
  ///
  /// Three paths that lead to the dismiss screen:
  ///
  /// 1. Alarm enters alerting/snoozed state while the app is in the foreground
  ///    or the Flutter engine is running in the background → existing "update"
  ///    event with state == "unknown".
  ///
  /// 2. User taps "Do push-up" in the notification banner while the engine is
  ///    running → plugin emits "secondaryButtonTapped" event immediately.
  ///
  /// 3. App was killed when the banner was tapped (cold-start) or the engine
  ///    was suspended → AppLifecycleListener picks up the UserDefaults flag on
  ///    the next resume.
  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    _subscription?.cancel();
    _subscription = FlutterAlarmkit.alarmUpdates().listen((event) {
      if (event is! Map) return;

      final eventType = event['event'] as String?;

      // Path 1: normal alerting / snoozed state update.
      if (eventType == 'update') {
        final alarm = event['alarm'] as Map?;
        if (alarm == null) return;
        if (alarm['state'] != 'unknown') return;
        final alarmId = event['id'] as String?;
        if (alarmId == null) return;
        _pushDismiss(navigatorKey, alarmId);
        return;
      }

      // Path 2: plugin emitted this when AppDelegate received the notification
      // action while the Flutter engine was already running.
      if (eventType == 'secondaryButtonTapped') {
        // We don't trust the id from the notification identifier directly —
        // query AlarmKit to get the authoritative snoozed alarm id instead.
        getRingingAlarm().then((alarmId) {
          if (alarmId != null) _pushDismiss(navigatorKey, alarmId);
        });
      }
    });

    // Path 3: lifecycle fallback for cases where the stream missed the event.
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => checkAndNavigate(navigatorKey),
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

  static void _pushDismiss(GlobalKey<NavigatorState> navigatorKey, String alarmId) {
    // pushNamedAndRemoveUntil keeps only the root '/' route and pushes
    // '/alarm-dismiss', so calling this multiple times is idempotent.
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/alarm-dismiss',
      (route) => route.isFirst,
      arguments: alarmId,
    );
  }
}
