import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../subscription/services/analytics_service.dart';

/// Info about a burst within a cascade.
class NextBurst {
  final String burstId;
  final int timestampMs;
  final bool isAlerting;

  const NextBurst({
    required this.burstId,
    required this.timestampMs,
    required this.isAlerting,
  });
}

/// A currently-alerting alarm: its native AlarmKit id plus the `originalId` of
/// the cascade it belongs to. `id` is the actual ringing burst/master (matches
/// `getBurstsInWindow` output); `originalId` is what `cancelBurst` needs.
class RingingAlarm {
  final String id;
  final String originalId;

  /// Programmed fire time of this ring (ms since epoch). Lets callers keep the
  /// alarm that rang most recently. 0 for a `.relative` master with no fixed
  /// date.
  final int firedAtMs;

  const RingingAlarm({
    required this.id,
    required this.originalId,
    this.firedAtMs = 0,
  });
}

/// AlarmKit authorization state, mirrored from the native enum.
enum AlarmAuthorizationStatus { authorized, denied, notDetermined }

class AlarmChannel {
  static const _method = MethodChannel('levio/alarmkit');
  static const _events = EventChannel('levio/alarmkit/events');

  /// Default number of escalating bursts in a loud cascade. Mirror of the
  /// native `kBurstCount`. Gentle alarms pass 0 (master alert only).
  static const defaultBurstCount = 40;

  static Future<bool> requestAuthorization() async {
    return await _method.invokeMethod<bool>('requestAuthorization') ?? false;
  }

  /// Current authorization state without prompting. Returns [notDetermined]
  /// when the native channel is unavailable (e.g. iOS < 26).
  static Future<AlarmAuthorizationStatus> getAuthorizationStatus() async {
    try {
      final raw = await _method.invokeMethod<String>('getAuthorizationStatus');
      switch (raw) {
        case 'authorized':
          return AlarmAuthorizationStatus.authorized;
        case 'denied':
          return AlarmAuthorizationStatus.denied;
        default:
          return AlarmAuthorizationStatus.notDetermined;
      }
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] getAuthorizationStatus failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.getAuthorizationStatus', e, st);
      return AlarmAuthorizationStatus.notDetermined;
    } on MissingPluginException {
      return AlarmAuthorizationStatus.notDetermined;
    }
  }

  /// Opens the system Settings page for this app.
  static Future<void> openAppSettings() async {
    try {
      await _method.invokeMethod('openAppSettings');
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] openAppSettings failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.openAppSettings', e, st);
    }
  }

  /// Schedules a one-shot cascade: 1 master (.fixed) + 20 .fixed bursts, 20s
  /// apart, all sharing the returned `originalAlarmId`.
  static Future<String> scheduleOneShot({
    required int timestampMs,
    required String title,
    required String sfSymbol,
    required String secondaryLabel,
    String? soundPath,
    int burstCount = defaultBurstCount,
  }) async {
    final id = await _method.invokeMethod<String>('scheduleOneShot', {
      'timestampMs': timestampMs.toDouble(),
      'title': title,
      'sfSymbol': sfSymbol,
      'secondaryLabel': secondaryLabel,
      'burstCount': burstCount,
      if (soundPath != null) 'soundPath': soundPath,
    });
    return id!;
  }

  /// Schedules a recurrent cascade: 1 master (.relative weekly) + 20 .fixed
  /// bursts, 20s apart, starting at the next matching weekday at hour:minute.
  /// `weekdayMask` uses bit 0 = Monday … bit 6 = Sunday.
  static Future<String> scheduleRepeating({
    required int weekdayMask,
    required int hour,
    required int minute,
    required String title,
    required String sfSymbol,
    required String secondaryLabel,
    String? soundPath,
    int burstCount = defaultBurstCount,
  }) async {
    final id = await _method.invokeMethod<String>('scheduleRepeating', {
      'weekdayMask': weekdayMask,
      'hour': hour,
      'minute': minute,
      'title': title,
      'sfSymbol': sfSymbol,
      'secondaryLabel': secondaryLabel,
      'burstCount': burstCount,
      if (soundPath != null) 'soundPath': soundPath,
    });
    return id!;
  }

  /// Full cancel: master + every burst + saved config. Use on alarm delete or
  /// disable. For mission completion, prefer [cancelBurstsKeepMaster] so the
  /// weekly master stays armed for next week.
  static Future<void> cancel(String id) async {
    try {
      await _method.invokeMethod('cancel', {'id': id});
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] cancel($id) failed — code=${e.code} | message=${e.message}');
      AnalyticsService.trackError('AlarmChannel.cancel', e, st);
      rethrow;
    }
  }

  /// Cancels a single burst. Used by the suppression timer. Never cancels
  /// the master.
  static Future<void> cancelBurst({
    required String originalId,
    required String burstId,
  }) async {
    try {
      await _method.invokeMethod('cancelBurst', {
        'originalId': originalId,
        'burstId': burstId,
      });
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] cancelBurst($originalId/$burstId) failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.cancelBurst', e, st);
    }
  }

  /// Mission success: silences the currently-alerting master (preserves the
  /// weekly schedule for .relative, deletes the .fixed one-shot), cancels
  /// every remaining burst. Master stays alive for recurrent alarms — follow
  /// up with [rescheduleForNextFire] to queue the next 20 bursts.
  static Future<void> cancelBurstsKeepMaster(String originalId) async {
    try {
      await _method.invokeMethod('cancelBurstsKeepMaster', {'id': originalId});
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] cancelBurstsKeepMaster($originalId) failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.cancelBurstsKeepMaster', e, st);
    }
  }

  /// Silences only the master if it's currently alerting. Used on mission
  /// mount to stop the master ring without touching the queued bursts.
  static Future<void> dismissMasterRingIfAlerting(String originalId) async {
    try {
      await _method.invokeMethod('dismissMasterRingIfAlerting', {'id': originalId});
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] dismissMasterRingIfAlerting($originalId) failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.dismissMasterRingIfAlerting', e, st);
    }
  }

  /// For recurrent alarms: schedules a fresh set of 20 bursts for the next
  /// matching weekday strictly after today. For one-shot alarms: purges the
  /// saved config. Call after [cancelBurstsKeepMaster].
  static Future<void> rescheduleForNextFire(String originalId) async {
    try {
      await _method.invokeMethod('rescheduleForNextFire', {'id': originalId});
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] rescheduleForNextFire($originalId) failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.rescheduleForNextFire', e, st);
    }
  }

  /// Tops up the burst queue to 20 when the cascade is under-filled. Invoked
  /// on app open over a ringing alarm, on sync, and on ring events — no-op
  /// if the queue is already full. Lock-guarded natively against overlapping
  /// invocations for the same originalId.
  static Future<void> primeCascadeIfNeeded(String originalId) async {
    try {
      await _method.invokeMethod('primeCascadeIfNeeded', {'id': originalId});
    } on PlatformException catch (e, st) {
      debugPrint('[AlarmChannel] primeCascadeIfNeeded($originalId) failed: ${e.message}');
      AnalyticsService.trackError('AlarmChannel.primeCascadeIfNeeded', e, st);
    }
  }

  /// Returns the next burst — alerting wins, else soonest-future scheduled.
  /// Never returns the master. Null if no bursts remain.
  static Future<NextBurst?> getNextBurst(String originalId) async {
    final raw = await _method.invokeMapMethod<String, dynamic>('getNextBurst', {
      'id': originalId,
    });
    if (raw == null) return null;
    final burstId = raw['burstId'] as String?;
    final tsRaw = raw['timestampMs'];
    final isAlerting = raw['isAlerting'] as bool? ?? false;
    if (burstId == null) return null;
    final ts = tsRaw is double
        ? tsRaw.toInt()
        : (tsRaw is int ? tsRaw : 0);
    return NextBurst(burstId: burstId, timestampMs: ts, isAlerting: isAlerting);
  }

  /// Returns the IDs of every burst firing within `windowMs` (including
  /// currently-alerting bursts). Used by suppression to cancel all bursts in
  /// a 10s window in one pass.
  static Future<List<String>> getBurstsInWindow(
    String originalId, {
    int windowMs = 10000,
  }) async {
    final raw = await _method.invokeListMethod<String>('getBurstsInWindow', {
      'id': originalId,
      'windowMs': windowMs,
    });
    return raw ?? [];
  }

  /// Removes the saved config for a cascade (and any leftover bursts).
  static Future<void> cleanupConfig(String id) async {
    await _method.invokeMethod('cleanupConfig', {'id': id});
  }

  static Future<List<String>> getAlarmIds() async {
    final result = await _method.invokeListMethod<String>('getAlarmIds');
    return result ?? [];
  }

  /// Returns full info for each cascade (keyed by `originalId`).
  static Future<List<Map<String, dynamic>>> getAlarms() async {
    final raw = await _method.invokeListMethod<Object?>('getAlarms') ?? [];
    return raw
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }

  /// Debug: returns every native AlarmKit alarm (unfiltered), enriched with
  /// role (master/burst/unknown), originalId, and schedule details.
  static Future<List<Map<String, dynamic>>> getRawAlarms() async {
    final raw = await _method.invokeListMethod<Object?>('getRawAlarms') ?? [];
    return raw
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }

  /// Returns the `originalId` of any cascade whose burst OR master is
  /// currently alerting.
  static Future<String?> getRingingId() async {
    return _method.invokeMethod<String?>('getRingingId');
  }

  /// Returns every currently-alerting alarm with both its native AlarmKit id
  /// and its cascade `originalId`. The native `id` lets suppression spare the
  /// burst that's physically ringing (matched against [getBurstsInWindow])
  /// while still cancelling the rest of that cascade via `originalId`.
  static Future<List<RingingAlarm>>  getRingingAlarms() async {
    final raw =
        await _method.invokeListMethod<Object?>('getRingingAlarms') ?? [];
    return raw.whereType<Map>().map((m) {
      final c = m.cast<String, dynamic>();
      final id = c['id'] as String;
      final ts = c['firedAtMs'];
      return RingingAlarm(
        id: id,
        originalId: c['originalId'] as String? ?? id,
        firedAtMs: ts is num ? ts.toInt() : 0,
      );
    }).toList();
  }

  /// Returns the `originalId` of every cascade currently alerting. Used on
  /// mission completion to sweep all alarms that rang at the same time.
  static Future<List<String>> getRingingIds() async {
    final alarms = await getAlarms();
    return alarms
        .where((a) => a['state'] == 'alerting')
        .map((a) => a['id'] as String)
        .toList();
  }

  static Stream<Map<Object?, Object?>> get events =>
      _events.receiveBroadcastStream().cast<Map<Object?, Object?>>();

  /// Converts `repeatDays` (index 0 = Sunday … 6 = Saturday) to a weekday mask
  /// where bit 0 = Monday … bit 6 = Sunday.
  static int toWeekdayMask(List<bool> days) {
    const mapping = [6, 0, 1, 2, 3, 4, 5];
    var mask = 0;
    for (var i = 0; i < days.length; i++) {
      if (days[i]) mask |= (1 << mapping[i]);
    }
    return mask;
  }
}
