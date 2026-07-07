import 'dart:async';

import 'package:flutter/material.dart';
import '../../wakeup/services/history_service.dart';
import 'alarm_channel.dart';
import '../cubit/alarm_state.dart';
import 'alarm_firestore_service.dart';

/// Tracks whether the `/alarm-dismiss` route is currently anywhere on the
/// navigator stack, backed by real navigator callbacks instead of a manually
/// toggled flag. This stays correct even when several alarms ring at once.
///
/// Attach it via `navigatorObservers` in [MaterialApp].
class DismissRouteObserver extends NavigatorObserver {
  static const dismissRouteName = '/alarm-dismiss';

  /// Mirror of the route names currently on the navigator stack (in order).
  static final List<String?> _stack = [];

  /// True while a dismiss screen is on the stack.
  static bool get isDismissScreenActive => _stack.contains(dismissRouteName);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _stack.remove(oldRoute?.settings.name);
    _stack.add(newRoute?.settings.name);
  }
}

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
          // Fast path — the authoritative guard is in _pushDismiss, which
          // re-checks synchronously against the real navigator stack.
          if (DismissRouteObserver.isDismissScreenActive) return;

          // Ring events carry the burst id (`id`) and the logical cascade id
          // (`originalId`). Prefer originalId for Firestore lookup.
          final burstId = event['id'] as String?;
          final originalId = (event['originalId'] as String?) ?? burstId;
          if (originalId == null) return;

          // If the master just rang with an under-filled burst queue (user
          // ignored last week's cascade), top up to 20 now so the user still
          // gets the full cascade pressure. No-op when the queue is full.
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

          final firstMission = firestoreEntry.missions.isNotEmpty
              ? firestoreEntry.missions.first
              : null;
          HistoryService.createPendingSession(
            alarmId: firestoreEntry.id,
            missionType: firstMission?.type,
            soundId: firestoreEntry.soundId,
            isSleep: firestoreEntry.isSleep,
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
        if (DismissRouteObserver.isDismissScreenActive) return;

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
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[AlarmService] _pushDismiss: navigator not ready — skipping');
      return;
    }

    // Authoritative guard: never stack a second dismiss screen. Backed by the
    // real navigator stack (DismissRouteObserver) and checked synchronously
    // right before pushing, so two alarms ringing at once can't both push —
    // the first push updates the observer before the second call runs.
    if (DismissRouteObserver.isDismissScreenActive) {
      debugPrint('[AlarmService] _pushDismiss: dismiss already active — skipping');
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      '/alarm-dismiss',
      (route) => route.isFirst,
      arguments: args,
    );
  }
}
