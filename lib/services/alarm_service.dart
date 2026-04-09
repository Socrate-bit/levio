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

  static Future<Map<String, String>?> getRingingAlarm() async {
    final plugin = FlutterAlarmkit();
    final prefs = await SharedPreferences.getInstance();
    final alarms = await plugin.getAlarms();
    debugPrint('[AlarmService] getRingingAlarm: ${alarms.length} alarm(s) found');
    for (final alarm in alarms) {
      final state = alarm['state'] as String?;
      final id = alarm['id'] as String?;
      debugPrint('[AlarmService]   id=$id  state=$state');
      if (state == 'unknown') {
        if (id == null) continue;
        final challenge = prefs.getString(_challengeKey(id)) ?? 'pushup';
        debugPrint('[AlarmService] → ringing alarm  id=$id  challenge=$challenge');
        return {'alarmId': id, 'challenge': challenge};
      }
    }
    debugPrint('[AlarmService] → no ringing alarm');
    return null;
  }

  static Future<void> checkAndNavigate(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    debugPrint('[AlarmService] checkAndNavigate called');
    await _printNativeDebugLog();

    // Always check for a ringing alarm first — handles the button-tap path
    // where OpenAlarmAppIntent (running in the widget extension process) can't
    // share UserDefaults with the main app without an App Group.
    final ringing = await getRingingAlarm();
    if (ringing != null) {
      debugPrint('[AlarmService] checkAndNavigate → ringing alarm found, navigating  args=$ringing');
      _pushDismiss(navigatorKey, ringing);
      return;
    }

    // Cold-start fallback: check the UserDefaults flag written by AppDelegate.
    if (!await _hasPendingDismiss()) {
      debugPrint('[AlarmService] checkAndNavigate → no ringing alarm and no pending dismiss, aborting');
      return;
    }
    await _clearPendingDismiss();
    debugPrint('[AlarmService] checkAndNavigate → pendingDismiss was true but no ringing alarm');
  }

  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    debugPrint('[AlarmService] listenForRing: starting stream + lifecycle listener');
    _subscription?.cancel();
    _subscription = FlutterAlarmkit.alarmUpdates().listen((event) async {
      if (event is! Map) {
        debugPrint('[AlarmService] stream: unexpected event type ${event.runtimeType}');
        return;
      }
      final eventType = event['event'] as String?;

      if (eventType == 'debugSchedule') {
        debugPrint('[AlarmService] 🔧 debugSchedule: '
            'alarmID=${event['alarmID']}  '
            'secondaryBehavior=${event['secondaryBehavior']}  '
            'secondaryIntentSet=${event['secondaryIntentSet']}');
        return;
      }

      debugPrint('[AlarmService] stream event: $event');

      if (eventType == 'update') {
        final alarm = event['alarm'] as Map?;
        if (alarm == null) return;
        final alarmState = alarm['state'];
        debugPrint('[AlarmService] update event: alarmState=$alarmState');
        if (alarmState != 'unknown') return;
        final alarmId = event['id'] as String?;
        if (alarmId == null) return;
        final prefs = await SharedPreferences.getInstance();
        final challenge = prefs.getString(_challengeKey(alarmId)) ?? 'pushup';
        debugPrint('[AlarmService] Path 1 → pushing dismiss  alarmId=$alarmId  challenge=$challenge');
        _pushDismiss(navigatorKey, {'alarmId': alarmId, 'challenge': challenge});
        return;
      }

      if (eventType == 'secondaryButtonTapped') {
        debugPrint('[AlarmService] Path 2 → secondaryButtonTapped, querying ringing alarm');
        final ringing = await getRingingAlarm();
        if (ringing != null) {
          debugPrint('[AlarmService] Path 2 → pushing dismiss  args=$ringing');
          _pushDismiss(navigatorKey, ringing);
        } else {
          debugPrint('[AlarmService] Path 2 → no ringing alarm found after secondaryButtonTapped');
        }
      }

      // intentFired = OpenAlarmAppIntent.perform() ran in the main app process.
      if (eventType == 'intentFired') {
        debugPrint('[AlarmService] ✅ intentFired received → intent IS running in main process');
        final ringing = await getRingingAlarm();
        if (ringing != null) {
          debugPrint('[AlarmService] intentFired → pushing dismiss  args=$ringing');
          _pushDismiss(navigatorKey, ringing);
        } else {
          debugPrint('[AlarmService] intentFired → no ringing alarm (already stopped?)');
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

  /// Reads native debug counters written by OpenAlarmAppIntent.perform()
  /// and AppDelegate.userNotificationCenter and prints them to Flutter output.
  static Future<void> _printNativeDebugLog() async {
    try {
      final log = await _actionChannel.invokeMethod<Map>('getDebugLog');
      if (log != null) {
        debugPrint('[AlarmService] native debug log: '
            'pendingDismiss=${log['pendingDismiss']}  '
            'intentFiredCount=${log['intentFiredCount']}  '
            'delegateFiredCount=${log['delegateFiredCount']}');
      }
    } catch (e) {
      debugPrint('[AlarmService] _printNativeDebugLog error: $e');
    }
  }

  static void _pushDismiss(GlobalKey<NavigatorState> navigatorKey, Map<String, String> args) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/alarm-dismiss',
      (route) => route.isFirst,
      arguments: args,
    );
  }
}