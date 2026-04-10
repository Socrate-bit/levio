import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../missions/models/mission.dart';
import '../../wakeup/services/history_service.dart';
import 'alarm_channel.dart';

class AlarmService {
  static StreamSubscription? _subscription;
  static AppLifecycleListener? _lifecycleListener;

  static const _actionChannel = MethodChannel('levio/alarm-action');

  static String _challengeKey(String id) => 'challenge_$id';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns nav args map for the first currently-alerting alarm, or null.
  static Future<Map<String, String>?> getRingingAlarm() async {
    final id = await AlarmChannel.getRingingId();
    debugPrint('[AlarmService] getRingingAlarm: ringingId=$id');
    if (id == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final challenge = prefs.getString('mission_$id') ??
        prefs.getString(_challengeKey(id)) ??
        'pushUps';
    final mathDiff = prefs.getString('math_diff_$id') ?? 'easy';
    final customObj = prefs.getString('custom_obj_$id') ?? '';
    debugPrint('[AlarmService] → ringing alarm  id=$id  challenge=$challenge');
    return {
      'alarmId': id,
      'challenge': challenge,
      'mathDifficulty': mathDiff,
      'customObject': customObj,
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
        final prefs = await SharedPreferences.getInstance();
        final challenge = prefs.getString('mission_$alarmId') ??
            prefs.getString(_challengeKey(alarmId)) ??
            'pushUps';
        final mathDiff = prefs.getString('math_diff_$alarmId') ?? 'easy';
        final customObj = prefs.getString('custom_obj_$alarmId') ?? '';
        final soundId = prefs.getString('sound_$alarmId') ?? 'default';
        final missionType = missionTypeFromString(challenge);
        HistoryService.createPendingSession(
          alarmId: alarmId,
          missionType: missionType,
          soundId: soundId,
        ).then((sessionId) {
          prefs.setString('pending_session_$alarmId', sessionId);
        }).ignore();
        debugPrint('[AlarmService] ring → pushing dismiss  alarmId=$alarmId  challenge=$challenge');
        _pushDismiss(navigatorKey, {
          'alarmId': alarmId,
          'challenge': challenge,
          'mathDifficulty': mathDiff,
          'customObject': customObj,
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
