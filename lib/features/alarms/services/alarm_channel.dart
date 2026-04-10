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
    await _method.invokeMethod('cancel', id);
  }

  static Future<void> stop(String id) async {
    await _method.invokeMethod('stop', id);
  }

  static Future<void> markCompleted(String id) async {
    await _method.invokeMethod('markCompleted', id);
  }

  static Future<void> dismissAlarm(String id) async {
    await markCompleted(id);
    await stop(id);
  }

  static Future<List<String>> getAlarmIds() async {
    final result = await _method.invokeListMethod<String>('getAlarmIds');
    return result ?? [];
  }

  static Future<String?> getRingingId() async {
    return _method.invokeMethod<String?>('getRingingId');
  }

  /// Returns a map of {oldId → newId} for alarms rescheduled natively while
  /// the app was killed. Keys are consumed (cleared) on the native side.
  static Future<Map<String, String>> getPendingReschedules() async {
    final raw = await _method.invokeMapMethod<String, String>('getPendingReschedules');
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
