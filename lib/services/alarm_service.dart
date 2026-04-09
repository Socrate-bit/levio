import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

class AlarmService {
  static StreamSubscription? _subscription;

  /// Returns the ID of the first currently-alerting alarm, if any.
  /// When AlarmKit transitions a one-shot alarm to alerting state,
  /// toDictionary() maps the state to "unknown" (the @unknown default branch).
  static Future<String?> getRingingAlarm() async {
    final plugin = FlutterAlarmkit();
    final alarms = await plugin.getAlarms();
    for (final alarm in alarms) {
      final state = alarm['state'] as String?;
      if (state == 'unknown') return alarm['id'] as String?;
    }
    return null;
  }

  /// Subscribes to alarm updates and navigates to the dismiss screen whenever
  /// an alarm transitions to alerting state (state == "unknown").
  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    _subscription?.cancel();
    _subscription = FlutterAlarmkit.alarmUpdates().listen((event) {
      if (event is! Map) return;
      if (event['event'] != 'update') return;

      final alarm = event['alarm'] as Map?;
      if (alarm == null) return;
      if (alarm['state'] != 'unknown') return;

      final alarmId = event['id'] as String?;
      if (alarmId == null) return;

      navigatorKey.currentState?.pushNamed(
        '/alarm-dismiss',
        arguments: alarmId,
      );
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
