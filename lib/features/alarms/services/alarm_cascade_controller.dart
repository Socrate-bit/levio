import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../subscription/services/analytics_service.dart';
import '../../wakeup/services/history_service.dart';
import 'alarm_channel.dart';
import 'alarm_firestore_service.dart';

/// Manages the cascade while a mission is in progress. Started when the user
/// taps Start on the mission screen and stopped on completion, inactivity, or
/// mid-sequence advance.
///
/// Two periodic timers:
///
/// 1. **Suppression** — every 5s. With `keep_alarm_during_mission` off
///    (default), silences every live cascade — this mission's own alarm *and*
///    any concurrent alarm that fired at the same time — so nothing rings
///    during the mission. With the pref on, enforces "only one alarm ringing
///    at a time": keeps the cascade currently ringing alive and silences every
///    other cascade; suppresses nothing while none is alerting (so the next
///    burst can ring).
/// 2. **Inactivity watchdog** — every 5s, checks time since last progress. If
///    ≥ 60s with no progress signal, fires [onInactivityTimeout] and stops the
///    suppression timer so bursts resume ringing.
///
/// Flutter pauses timers when the app is backgrounded, which is exactly the
/// dead-man's-switch behavior we want: the next burst fires and reopens the
/// app via `openAppWhenRun` on the alarm intents.
class AlarmCascadeController {
  final String alarmId;
  final VoidCallback? onInactivityTimeout;

  /// True when the mission was launched EARLY from Home ("Start now"), before the
  /// alarm rang. On [finish] this consumes today's occurrence (which is still
  /// scheduled, not alerting) instead of the normal dismiss path.
  final bool earlyStart;

  static const _inactivityTimeout = Duration(seconds: 30);
  static const _suppressionWindowMs = 10000;

  Timer? _suppressionTimer;
  Timer? _watchdogTimer;
  DateTime _lastProgressAt = DateTime.now();
  bool _active = false;
  bool _disposed = false;
  bool _keepRinging = false;

  AlarmCascadeController({
    required this.alarmId,
    this.onInactivityTimeout,
    this.earlyStart = false,
  });

  /// Starts the suppression timer and inactivity watchdog. Call when the user
  /// taps Start on the mission screen. Captures the `keep_alarm_during_mission`
  /// pref to choose between total silence and "keep one ringing". Idempotent.
  ///
  /// Pass [enableInactivityWatchdog] false to skip the watchdog entirely — used
  /// by the routine mission, which the user completes at their own pace and must
  /// never be bounced back to the start screen on inactivity.
  Future<void> start({bool enableInactivityWatchdog = true}) async {
    if (_active || _disposed) return;
    final prefs = await SharedPreferences.getInstance();
    // Guard the async gap: finish()/dispose() may have run while we were
    // awaiting prefs — don't arm timers on a torn-down controller.
    if (_disposed) return;
    _keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;

    _active = true;
    _lastProgressAt = DateTime.now();

    _suppressionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _suppressWindow(),
    );
    if (enableInactivityWatchdog) {
      _watchdogTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkInactivity(),
      );
    }

    // Immediate pass so concurrent cascades are silenced as soon as the
    // mission starts.
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

  /// Mission completion: stops timers, dismisses this alarm's cascade, then
  /// sweeps every OTHER alarm still ringing so alarms scheduled for the same
  /// time are cleared in one pass instead of each spawning its own mission.
  Future<void> finish() async {
    _disposed = true;
    stopSuppression();
    if (earlyStart) {
      // The alarm never rang — its master is still scheduled, so the normal
      // path would leave it to fire today. Consume today's occurrence and
      // re-arm for the next fire.
      await AlarmChannel.consumeTodayAndReschedule(alarmId);
    } else {
      await _dismissCascade(alarmId);
    }
    await _sweepConcurrentAlarms();
  }

  /// Silences a ringing master, cancels every remaining burst (preserving the
  /// master for recurrent alarms), and queues the next 20 bursts for the next
  /// matching weekday. One-shot alarms self-cancel their master after firing —
  /// `rescheduleForNextFire` just cleans up their saved config.
  Future<void> _dismissCascade(String id) async {
    try {
      await AlarmChannel.cancelBurstsKeepMaster(id);
    } catch (e, st) {
      debugPrint(
        '[AlarmCascadeController] cancelBurstsKeepMaster failed for $id: $e',
      );
      AnalyticsService.trackError(
        'AlarmCascadeController.finish.cancelBursts',
        e,
        st,
      );
    }
    try {
      await AlarmChannel.rescheduleForNextFire(id);
    } catch (e, st) {
      debugPrint(
        '[AlarmCascadeController] rescheduleForNextFire failed for $id: $e',
      );
      AnalyticsService.trackError(
        'AlarmCascadeController.finish.reschedule',
        e,
        st,
      );
    }
  }

  /// Dismisses every cascade — other than this mission's — still alerting at
  /// completion time, logging each as an auto-dismissed session so it doesn't
  /// re-trigger a mission and doesn't inflate totalWakeups.
  Future<void> _sweepConcurrentAlarms() async {
    final List<String> ringingIds;
    try {
      ringingIds = await AlarmChannel.getRingingIds();
    } catch (e, st) {
      debugPrint('[AlarmCascadeController] getRingingIds failed: $e');
      AnalyticsService.trackError(
        'AlarmCascadeController.sweep.getRingingIds',
        e,
        st,
      );
      return;
    }

    for (final id in ringingIds) {
      if (id == alarmId) continue;
      await _dismissCascade(id);
      final entry = await AlarmFirestoreService.getAlarm(id);
      final firstMission = (entry != null && entry.missions.isNotEmpty)
          ? entry.missions.first
          : null;
      HistoryService.recordAutoDismissedSession(
        alarmId: id,
        missionType: firstMission?.type,
        soundId: entry?.soundId ?? 'default',
      ).ignore();
    }
  }

  void dispose() {
    _disposed = true;
    stopSuppression();
  }

  /// One suppression pass. Behavior depends on the `keep_alarm_during_mission`
  /// pref captured at [start]:
  ///
  /// - **Suppress mode** (default): silences every live cascade — this
  ///   mission's own alarm *and* any concurrent alarm that fired at the same
  ///   time — so nothing rings while the mission is on screen.
  /// - **Keep-ringing mode**: enforces "only one alarm ringing at a time".
  ///   While some cascade is alerting, suppresses every OTHER cascade; while
  ///   none is alerting, suppresses nothing so the next burst can ring.
  Future<void> _suppressWindow() async {
    try {
      // Suppress mode: silence every cascade. Keep-ringing mode: keep the one
      // currently ringing and silence the rest.
      if (!_keepRinging) {
        await _suppressAllExcept();
        return;
      }
      final ringing = await AlarmChannel.getRingingAlarms();
      // Nothing ringing — let the next burst through instead of pre-cancelling.
      if (ringing.isEmpty) return;
      // Keep the alarm that rang most recently (latest fire time), not just the
      // last one in the list — list order doesn't track when each started.
      final keep = ringing.reduce(
        (a, b) => b.firedAtMs >= a.firedAtMs ? b : a,
      );
      await _suppressAllExcept(keepNativeId: keep.id);
    } catch (e, st) {
      debugPrint('[AlarmCascadeController] suppressWindow failed: $e');
      AnalyticsService.trackError(
        'AlarmCascadeController._suppressWindow',
        e,
        st,
      );
    }
  }

  /// Cancels every burst scheduled within the suppression window for each live
  /// cascade except the one ringing right now.
  ///
  /// [keepNativeId] is the native AlarmKit id of the alerting ring we keep
  /// (matches both `getBurstsInWindow` output and each cascade's `masterId`),
  /// or null in suppress mode where everything is silenced. It serves two
  /// guards:
  /// - Burst spare: a burst whose id equals [keepNativeId] is not cancelled.
  /// - Master spare: a cascade's master is dismissed UNLESS that master is
  ///   itself the alerting ring (`masterId == keepNativeId`). Comparing
  ///   against `masterId` — not `originalId` — matters because a burst shares
  ///   its cascade's `originalId`: when a burst is the ring, the master must
  ///   still be silenced so only the burst keeps ringing.
  ///
  /// Enumerates *all* live cascades (via [AlarmChannel.getAlarms]) rather than
  /// only the currently-alerting ones, so a concurrent alarm sitting between
  /// two of its own bursts is still caught — `getBurstsInWindow` decides what
  /// to cancel per cascade from each burst's programmed fire time. The cascade
  /// that's actively ringing this instant is always spared so we never cut a
  /// ring off mid-alert; only its concurrents are silenced. Cancelling
  /// batch-wise (not just "the next one") keeps suppression robust when
  /// overlapping bursts have accumulated.
  Future<void> _suppressAllExcept({String? keepNativeId}) async {
    final alarms = await AlarmChannel.getAlarms();
    for (final alarm in alarms) {
      final id = alarm['id'] as String?;
      if (id == null) continue;
      // Dismiss the master unless it is itself the alerting ring — silencing
      // it then would cut off the alert we keep. A burst ringing in this same
      // cascade does NOT spare the master: only the burst should ring.
      final masterId = alarm['masterId'] as String?;
      if (masterId != keepNativeId) {
        await AlarmChannel.dismissMasterRingIfAlerting(id);
      }
      final burstIds = await AlarmChannel.getBurstsInWindow(
        id,
        windowMs: _suppressionWindowMs,
      );
      for (final burstId in burstIds) {
        if (burstId == keepNativeId) {
          continue;
        }
        await AlarmChannel.cancelBurst(originalId: id, burstId: burstId);
      }
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
