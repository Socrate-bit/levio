import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static StreamSubscription? _subscription;

  static String _challengeKey(String id) => 'challenge_$id';

  /// Returns nav args map with 'alarmId' and 'challenge' for the first
  /// alerting alarm, or null if none is ringing.
  static Future<Map<String, String>?> getRingingAlarm() async {
    final plugin = FlutterAlarmkit();
    final prefs = await SharedPreferences.getInstance();
    final alarms = await plugin.getAlarms();
    for (final alarm in alarms) {
      final state = alarm['state'] as String?;
      if (state == 'unknown') {
        final id = alarm['id'] as String?;
        if (id == null) continue;
        final challenge = prefs.getString(_challengeKey(id)) ?? 'pushup';
        return {'alarmId': id, 'challenge': challenge};
      }
    }
    return null;
  }

  /// Subscribes to alarm updates and navigates to the dismiss screen whenever
  /// an alarm transitions to alerting state (state == "unknown").
  static void listenForRing(GlobalKey<NavigatorState> navigatorKey) {
    _subscription?.cancel();
    _subscription = FlutterAlarmkit.alarmUpdates().listen((event) async {
      if (event is! Map) return;
      if (event['event'] != 'update') return;

      final alarm = event['alarm'] as Map?;
      if (alarm == null) return;
      if (alarm['state'] != 'unknown') return;

      final alarmId = event['id'] as String?;
      if (alarmId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final challenge = prefs.getString(_challengeKey(alarmId)) ?? 'pushup';

      navigatorKey.currentState?.pushNamed(
        '/alarm-dismiss',
        arguments: {'alarmId': alarmId, 'challenge': challenge},
      );
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
