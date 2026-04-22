import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

class AlarmChannel {
  static const _method = MethodChannel('levio/alarmkit');
  static const _events = EventChannel('levio/alarmkit/events');

  static Future<bool> requestAuthorization() async {
    return await _method.invokeMethod<bool>('requestAuthorization') ?? false;
  }

  /// Schedules a one-shot **cascade** — 24 native alarms, 15s apart, all
  /// sharing the returned `originalAlarmId`.
  static Future<String> scheduleOneShot({
    required int timestampMs,
    required String title,
    required String sfSymbol,
    required String secondaryLabel,
    String? soundPath,
  }) async {
    final id = await _method.invokeMethod<String>('scheduleOneShot', {
      'timestampMs': timestampMs.toDouble(),
      'title': title,
      'sfSymbol': sfSymbol,
      'secondaryLabel': secondaryLabel,
      if (soundPath != null) 'soundPath': soundPath,
    });
    return id!;
  }

  /// Schedules a repeating **cascade** — 24 native alarms, 15s apart, starting
  /// at the next matching weekday at hour:minute. `weekdayMask` uses bit 0 =
  /// Monday … bit 6 = Sunday.
  static Future<String> scheduleRepeating({
    required int weekdayMask,
    required int hour,
    required int minute,
    required String title,
    required String sfSymbol,
    required String secondaryLabel,
    String? soundPath,
  }) async {
    final id = await _method.invokeMethod<String>('scheduleRepeating', {
      'weekdayMask': weekdayMask,
      'hour': hour,
      'minute': minute,
      'title': title,
      'sfSymbol': sfSymbol,
      'secondaryLabel': secondaryLabel,
      if (soundPath != null) 'soundPath': soundPath,
    });
    return id!;
  }

  /// Cancels every remaining burst of the cascade (including any alerting one)
  /// and clears the saved config. Use on alarm delete or disable.
  static Future<void> cancel(String id) async {
    try {
      await _method.invokeMethod('cancel', {'id': id});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] cancel($id) failed — code=${e.code} | message=${e.message}');
      rethrow;
    }
  }

  /// Cancels a single burst within a cascade. Used by the in-app suppression
  /// timer to silence the next upcoming (or currently alerting) burst while
  /// the user is on the mission screen.
  static Future<void> cancelBurst({
    required String originalId,
    required String burstId,
  }) async {
    try {
      await _method.invokeMethod('cancelBurst', {
        'originalId': originalId,
        'burstId': burstId,
      });
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] cancelBurst($originalId/$burstId) failed: ${e.message}');
    }
  }

  /// For recurrent alarms: cancels any remaining bursts and schedules a fresh
  /// 24-burst cascade for the next matching weekday **strictly after today**.
  /// No-op for one-shot alarms.
  static Future<void> rescheduleForNextWeek(String originalId) async {
    try {
      await _method.invokeMethod('rescheduleForNextWeek', {'id': originalId});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] rescheduleForNextWeek($originalId) failed: ${e.message}');
    }
  }

  /// For recurrent alarms: if the `.relative(weekly)` safety-net burst is the
  /// only thing left alive (all 23 `.fixed` bursts have fired/expired), schedule
  /// a fresh set of `.fixed` bursts for the next matching weekday. Preserves
  /// the originalId and the live `.relative` burst. No-op otherwise.
  static Future<void> primeCascadeIfNeeded(String originalId) async {
    try {
      await _method.invokeMethod('primeCascadeIfNeeded', {'id': originalId});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] primeCascadeIfNeeded($originalId) failed: ${e.message}');
    }
  }

  /// Returns the next burst to act on for this cascade — either the currently
  /// alerting burst, or the soonest-future scheduled one. Null if none.
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

  /// Returns the `originalId` of any cascade whose burst is currently alerting.
  static Future<String?> getRingingId() async {
    return _method.invokeMethod<String?>('getRingingId');
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
