import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_channel.dart';

/// Manages the cascade while a mission is on screen.
///
/// Two periodic timers:
///
/// 1. **Suppression** — every 5s, cancels every burst scheduled to fire in
///    the next 10s (including currently-alerting ones) and silences the
///    master ring if alerting. Skipped entirely if the global
///    `keep_alarm_during_mission` pref is on.
/// 2. **Inactivity watchdog** — every 2s, checks time since last progress.
///    If ≥ 20s with no progress signal, fires [onInactivityTimeout] and
///    stops the suppression timer so bursts resume ringing.
///
/// Flutter pauses timers when the app is backgrounded, which is exactly the
/// dead-man's-switch behavior we want: the next burst fires and reopens the
/// app via `openAppWhenRun` on the alarm intents.
class AlarmCascadeController {
  final String alarmId;
  final VoidCallback? onInactivityTimeout;

  static const _inactivityTimeout = Duration(seconds: 20);
  static const _suppressionWindowMs = 10000;

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
      (_) => _suppressWindow(),
    );
    _watchdogTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkInactivity(),
    );

    // Immediate pass so the currently-ringing master/burst is silenced as
    // soon as the mission screen mounts.
    unawaited(_suppressWindow());
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

  /// Mission completion: stops timers, silences any ringing master, cancels
  /// every remaining burst (preserving master for recurrent alarms), and
  /// queues the next 20 bursts for the next matching weekday. One-shot
  /// alarms self-cancel their master after firing — `rescheduleForNextFire`
  /// just cleans up their saved config.
  Future<void> finish() async {
    _disposed = true;
    stopSuppression();
    try {
      await AlarmChannel.cancelBurstsKeepMaster(alarmId);
    } catch (e) {
      debugPrint('[AlarmCascadeController] cancelBurstsKeepMaster failed for $alarmId: $e');
    }
    try {
      await AlarmChannel.rescheduleForNextFire(alarmId);
    } catch (e) {
      debugPrint('[AlarmCascadeController] rescheduleForNextFire failed for $alarmId: $e');
    }
  }

  void dispose() {
    _disposed = true;
    stopSuppression();
  }

  /// Cancels every burst firing within the next 10s in one pass and silences
  /// the master ring if it's currently alerting. Cancelling batch-wise (not
  /// just "the next one") keeps suppression robust when the user has been
  /// making progress and accumulated overlapping bursts.
  Future<void> _suppressWindow() async {
    try {
      await AlarmChannel.dismissMasterRingIfAlerting(alarmId);
      final ids = await AlarmChannel.getBurstsInWindow(
        alarmId,
        windowMs: _suppressionWindowMs,
      );
      for (final burstId in ids) {
        await AlarmChannel.cancelBurst(originalId: alarmId, burstId: burstId);
      }
    } catch (e) {
      debugPrint('[AlarmCascadeController] suppressWindow failed: $e');
    }
  }

  void _checkInactivity() {
    final elapsed = DateTime.now().difference(_lastProgressAt);
    if (elapsed < _inactivityTimeout) return;
    debugPrint(
      '[AlarmCascadeController] inactivity timeout for $alarmId — ${elapsed.inSeconds}s since last progress',
    );
    stopSuppression();
    onInactivityTimeout?.call();
  }
}
