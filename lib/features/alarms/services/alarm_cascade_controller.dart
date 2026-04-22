import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_channel.dart';

/// Manages the 24-burst cascade while a mission is on screen.
///
/// Two periodic timers:
///
/// 1. **Suppression** — every 5s, cancels the currently alerting burst and
///    any next-scheduled burst about to fire. Skipped entirely if the global
///    `keep_alarm_during_mission` pref is on.
/// 2. **Inactivity watchdog** — every 2s, checks time since last progress.
///    If ≥ 60s with no progress signal, fires [onInactivityTimeout] and
///    stops the suppression timer so bursts resume ringing.
///
/// Flutter pauses timers when the app is backgrounded, which is exactly the
/// dead-man's-switch behavior we want: the next burst fires and reopens the
/// app via `openAppWhenRun` on the alarm intents.
class AlarmCascadeController {
  final String alarmId;
  final VoidCallback? onInactivityTimeout;

  Timer? _suppressionTimer;
  Timer? _watchdogTimer;
  DateTime _lastProgressAt = DateTime.now();
  bool _active = false;
  bool _disposed = false;

  AlarmCascadeController({
    required this.alarmId,
    this.onInactivityTimeout,
  });

  /// Starts the suppression + inactivity watchdog if the user opted out of
  /// "keep ringing during mission". Idempotent.
  Future<void> start() async {
    if (_active || _disposed) return;
    final prefs = await SharedPreferences.getInstance();
    // Guard the async gap: finish()/dispose() may have run while we were
    // awaiting prefs — don't arm timers on a torn-down controller.
    if (_disposed) return;
    final keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;
    if (keepRinging) return;

    _active = true;
    _lastProgressAt = DateTime.now();

    _suppressionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _suppressNext(),
    );
    _watchdogTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkInactivity(),
    );

    // Also try an immediate suppression so the currently ringing burst is
    // silenced as soon as the mission screen mounts.
    unawaited(_suppressNext());
  }

  /// Mission screens call this each time the user makes meaningful progress
  /// (rep counted, key typed, shake detected, photo captured, phrase spoken).
  /// Resets the inactivity timer.
  void reportProgress() {
    _lastProgressAt = DateTime.now();
  }

  /// Stops both timers without cancelling any native bursts.
  void stopSuppression() {
    _suppressionTimer?.cancel();
    _suppressionTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _active = false;
  }

  /// Called on mission completion: stops timers, cancels every remaining
  /// burst, and (for recurrent alarms) schedules a fresh cascade for next week.
  /// For one-shots, the native `rescheduleForNextWeek` also clears the saved
  /// config so it doesn't linger in UserDefaults.
  Future<void> finish() async {
    _disposed = true;
    stopSuppression();
    // Independent try/catch so a failure in one call doesn't abort the next —
    // particularly, a `cancel` error must not prevent a recurrent reschedule.
    try {
      await AlarmChannel.cancel(alarmId);
    } catch (e) {
      debugPrint('[AlarmCascadeController] cancel failed for $alarmId: $e');
    }
    try {
      await AlarmChannel.rescheduleForNextWeek(alarmId);
    } catch (e) {
      debugPrint('[AlarmCascadeController] rescheduleForNextWeek failed for $alarmId: $e');
    }
  }

  void dispose() {
    _disposed = true;
    stopSuppression();
  }

  Future<void> _suppressNext() async {
    try {
      final next = await AlarmChannel.getNextBurst(alarmId);
      if (next == null) return;

      // Cancel alerting immediately. For upcoming bursts, only cancel if
      // they're about to fire within the next suppression-tick window (~10s);
      // cancelling too early would silence the whole cascade before the
      // user's done.
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeUntilMs = next.timestampMs - now;
      if (next.isAlerting || timeUntilMs <= 10000) {
        await AlarmChannel.cancelBurst(
          originalId: alarmId,
          burstId: next.burstId,
        );
      }
    } catch (e) {
      debugPrint('[AlarmCascadeController] suppressNext failed: $e');
    }
  }

  void _checkInactivity() {
    final elapsed = DateTime.now().difference(_lastProgressAt);
    if (elapsed.inSeconds < 60) return;
    debugPrint(
      '[AlarmCascadeController] inactivity timeout for $alarmId — ${elapsed.inSeconds}s since last progress',
    );
    stopSuppression();
    onInactivityTimeout?.call();
  }
}
