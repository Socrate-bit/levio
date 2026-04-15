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

  // Cancel scheduled alarm based on id
  static Future<void> cancel(String id) async {
    try {
      await _method.invokeMethod('cancel', {'id': id});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] cancel($id) failed — code=${e.code} | message=${e.message} | details=${e.details}');
      rethrow;
    }
  }

  // Stop alarm to ring based on id
  static Future<void> stop(String id) async {
    try {
      await _method.invokeMethod('stop', {'id': id});
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] stop($id) failed — code=${e.code} | message=${e.message} | details=${e.details}');
      rethrow;
    }
  }

  /// Cleans up UserDefaults entries (config, stopped set)
  /// for a fully dismissed or removed alarm.
  static Future<void> cleanupConfig(String id) async {
    await _method.invokeMethod('cleanupConfig', {'id': id});
  }

  /// Removes the snooze link for an alarm ID.
  static Future<void> cleanupSnoozeLink(String id) async {
    await _method.invokeMethod('cleanupSnoozeLink', {'id': id});
  }

  /// Cancels all snooze alarms associated with an original alarm ID.
  static Future<void> cancelSnoozesForAlarm(String originalAlarmId) async {
    await _method.invokeMethod('cancelSnoozesForAlarm', {
      'originalAlarmId': originalAlarmId,
    });
  }

  /// Stops the native ringing alarm.
  static Future<void> dismissAlarm(String nativeAlarmId) async {
    final ringingId = await getRingingId() ?? nativeAlarmId;
    try {
      await stop(ringingId);
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] dismissAlarm: stop failed (code=${e.code}) — ${e.message} | details: ${e.details}');
    }
  }

  /// Schedules a mission snooze alarm that re-rings after [delaySeconds] if
  /// the mission is not completed in time. Returns the snooze UUID.
  static Future<String> scheduleMissionSnooze({
    required String nativeAlarmId,
    required String originalAlarmId,
    int delaySeconds = 120,
  }) async {
    final id = await _method.invokeMethod<String>('scheduleMissionSnooze', {
      'nativeAlarmId': nativeAlarmId,
      'originalAlarmId': originalAlarmId,
      'delaySeconds': delaySeconds,
    });
    return id!;
  }

  /// Cancels a mission snooze and cleans up its config/snooze link.
  static Future<void> cancelMissionSnooze(String? snoozeId) async {
    if (snoozeId == null) return;
    try {
      await cancel(snoozeId);
    } on PlatformException catch (_) {
      // Snooze may have already fired or been cancelled.
    }
    try {
      await cleanupConfig(snoozeId);
    } catch (_) {}
  }

  /// Stops the currently ringing alarm audio. Called when a mission completes
  /// and the alarm was kept ringing during the mission.
  static Future<void> stopRinging() async {
    final ringingId = await getRingingId();
    if (ringingId == null) return;
    try {
      await stop(ringingId);
    } on PlatformException catch (e) {
      debugPrint('[AlarmChannel] stopRinging failed: ${e.message}');
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
