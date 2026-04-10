import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmChannel {
  static const _method = MethodChannel('levio/alarmkit');
  static const _events = EventChannel('levio/alarmkit/events');

  static Future<bool> requestAuthorization() async {
    return await _method.invokeMethod<bool>('requestAuthorization') ?? false;
  }

  /// Schedules a one-shot alarm. Returns the native UUID string.
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

  /// Schedules a repeating alarm. Returns the native UUID string.
  /// [weekdayMask]: bit 0 = Monday … bit 6 = Sunday.
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

  static Future<void> cancel(String id) async {
    try {
      await _method.invokeMethod('cancel', {'id': id});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] cancel($id) failed — code=${e.code} | message=${e.message} | details=${e.details}');
      rethrow;
    }
  }

  static Future<void> stop(String id) async {
    try {
      await _method.invokeMethod('stop', {'id': id});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] stop($id) failed — code=${e.code} | message=${e.message} | details=${e.details}');
      rethrow;
    }
  }

  static Future<void> markCompleted(String id) async {
    await _method.invokeMethod('markCompleted', {'id': id});
  }

  /// Cleans up UserDefaults entries (config, completed flag, stopped set)
  /// for a fully dismissed or removed alarm.
  static Future<void> cleanupConfig(String id) async {
    await _method.invokeMethod('cleanupConfig', {'id': id});
  }

  static Future<void> dismissAlarm(String id) async {
    await markCompleted(id);
    try {
      await stop(id);
    } on PlatformException catch (e) {
      // The alarm may already be stopped by the system (race condition when the
      // user taps the native stop button before the challenge completes).
      // AlarmError 0 = alarm not in a stoppable state. Log and continue.
      debugPrint('[AlarmChannel] dismissAlarm: stop failed (code=${e.code}) — ${e.message} | details: ${e.details}');
    }
  }

  static Future<List<String>> getAlarmIds() async {
    final result = await _method.invokeListMethod<String>('getAlarmIds');
    return result ?? [];
  }

  /// Returns full native info for each scheduled alarm.
  static Future<List<Map<String, dynamic>>> getAlarms() async {
    final raw = await _method.invokeListMethod<Object?>('getAlarms') ?? [];
    return raw
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();
  }

  static Future<String?> getRingingId() async {
    return _method.invokeMethod<String?>('getRingingId');
  }

  /// Returns {snoozeId → originalId} for all active snooze alarms.
  /// Read-only — never clears keys. Used by _syncAlarms (orphan check)
  /// and getRingingAlarm (Firestore lookup fallback).
  static Future<Map<String, String>> getSnoozeMap() async {
    final raw = await _method.invokeMapMethod<String, String>('getSnoozeMap');
    return raw ?? {};
  }

  /// Same as [getPendingReschedules] but read-only — does NOT clear keys.
  /// Used by AlarmService for cold-start fallback before _syncAlarms runs.
  static Future<Map<String, String>> peekPendingReschedules() async {
    final raw = await _method.invokeMapMethod<String, String>('peekPendingReschedules');
    return raw ?? {};
  }

  /// Returns configs for recurring alarms that need to be re-scheduled
  /// after their snooze was created by StopAndRescheduleIntent.
  static Future<List<Map<String, dynamic>>> getPendingRecurringRestores() async {
    final raw = await _method.invokeListMethod<Map>('getPendingRecurringRestores');
    return raw?.map((m) => Map<String, dynamic>.from(m)).toList() ?? [];
  }

  static Stream<Map<Object?, Object?>> get events =>
      _events.receiveBroadcastStream().cast<Map<Object?, Object?>>();

  /// Converts repeatDays (index 0 = Sunday … 6 = Saturday) to a weekday mask
  /// where bit 0 = Monday … bit 6 = Sunday.
  static int toWeekdayMask(List<bool> days) {
    const mapping = [6, 0, 1, 2, 3, 4, 5]; // days index → mask bit
    var mask = 0;
    for (var i = 0; i < days.length; i++) {
      if (days[i]) mask |= (1 << mapping[i]);
    }
    return mask;
  }
}
