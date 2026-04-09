import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static StreamSubscription? _subscription;
  static AppLifecycleListener? _lifecycleListener;

  static const _actionChannel = MethodChannel('levio/alarm-action');

  static String _challengeKey(String id) => 'challenge_$id';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns nav args map with 'alarmId' and 'challenge' for the first
  /// currently-alerting (or snoozed) alarm, or null if none is ringing.
  static Future<Map<String, String>?> getRingingAlarm() async {
    final plugin = FlutterAlarmkit();
    final prefs = await SharedPreferences.getInstance();
    final alarms = await plugin.getAlarms();
    for (final alarm in alarms) {
      final state = alarm['state'] as String?;
      if (state == 'unknown') {
        final id = alarm['id'] as String?;
        if (id == null) continue;
        // Support both old 'challenge_X' key and new 'mission_X' key
        final challenge = prefs.getString('mission_$id') ??
            prefs.getString(_challengeKey(id)) ??
            'pushUps';
        return {'alarmId': id, 'challenge': challenge};
      }
    }
    return null;
  }

  static Future<bool> _hasPendingDismiss() async {
    try {
      return await _actionChannel.invokeMethod<bool>('hasPendingDismiss') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _clearPendingDismiss() async {
    try {
      await _actionChannel.invokeMethod('clearPendingDismiss');
    } catch (_) {}
  }

  static Future<void> checkAndNavigate(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (!await _hasPendingDismiss()) return;
    await _clearPendingDismiss();
    final ringing = await getRingingAlarm();
    if (ringing == null) return;
    _pushDismiss(navigatorKey, ringing);
  }

  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    _subscription?.cancel();
    _subscription = FlutterAlarmkit.alarmUpdates().listen((event) async {
      if (event is! Map) return;
      final eventType = event['event'] as String?;

      if (eventType == 'update') {
        final alarm = event['alarm'] as Map?;
        if (alarm == null) return;
        if (alarm['state'] != 'unknown') return;
        final alarmId = event['id'] as String?;
        if (alarmId == null) return;
        final prefs = await SharedPreferences.getInstance();
        final challenge = prefs.getString('mission_$alarmId') ??
            prefs.getString(_challengeKey(alarmId)) ??
            'pushUps';
        _pushDismiss(
            navigatorKey, {'alarmId': alarmId, 'challenge': challenge});
        return;
      }

      if (eventType == 'secondaryButtonTapped') {
        final ringing = await getRingingAlarm();
        if (ringing != null) _pushDismiss(navigatorKey, ringing);
      }
    });

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

  static void _pushDismiss(
      GlobalKey<NavigatorState> navigatorKey, Map<String, String> args) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/alarm-dismiss',
      (route) => route.isFirst,
      arguments: args,
    );
  }
}
