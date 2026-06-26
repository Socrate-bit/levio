import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/generated/app_localizations.dart';
import '../../subscription/services/analytics_service.dart';
import '../cubit/alarm_state.dart';

/// Schedules the optional pre-alarm "bedtime reminder" local notification for
/// sleep alarms (a configurable number of minutes before the alarm rings).
///
/// This is independent from the AlarmKit cascade — it's a plain iOS local
/// notification used purely as a heads-up, so all of its work is best-effort:
/// a failure here must never block scheduling the actual alarm.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initializes the plugin and the timezone database. Call once at startup.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await _localTimeZone()));
      const settings = InitializationSettings(
        iOS: DarwinInitializationSettings(
          // Defer the permission prompt until the user enables a reminder.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (e, st) {
      debugPrint('[NotificationService] init failed: $e');
      AnalyticsService.trackError('NotificationService.init', e, st);
    }
  }

  /// Localizations for the device locale — the app follows the device locale,
  /// so reminders must too. Falls back to English for unsupported languages.
  static AppLocalizations get _l10n {
    final language = PlatformDispatcher.instance.locale.languageCode;
    try {
      return lookupAppLocalizations(Locale(language));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  /// Best-effort resolution of the device's IANA timezone name. The real zone
  /// (not UTC) is required so weekly `matchDateTimeComponents` recurrences fire
  /// at the correct local wall-clock time. Falls back to UTC on failure.
  static Future<String> _localTimeZone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return 'UTC';
    }
  }

  /// Requests iOS notification authorization. Call lazily the first time the
  /// user enables a reminder. Returns whether permission was granted.
  static Future<bool> requestPermission() async {
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } catch (e, st) {
      debugPrint('[NotificationService] requestPermission failed: $e');
      AnalyticsService.trackError('NotificationService.requestPermission', e, st);
      return false;
    }
  }

  /// Reconciles the reminder for [alarm]: cancels any existing reminder for it,
  /// then (re)schedules when it's an enabled sleep alarm with the reminder on.
  static Future<void> syncReminder(AppAlarmEntry alarm) async {
    await cancelReminder(alarm.id);
    if (!alarm.isSleep || !alarm.reminderEnabled || !alarm.isEnabled) return;

    try {
      await requestPermission();
      final l10n = _l10n;
      final body =
          alarm.name.isNotEmpty ? alarm.name : l10n.reminderNotificationBody;
      final title = l10n.reminderNotificationTitle;
      const details = NotificationDetails(iOS: DarwinNotificationDetails());

      if (alarm.isOneTime) {
        final fire = alarm.nextFireAt(DateTime.now()) ?? alarm.dateTime;
        final remindAt =
            fire.subtract(Duration(minutes: alarm.reminderMinutesBefore));
        if (remindAt.isAfter(DateTime.now())) {
          await _plugin.zonedSchedule(
            id: _baseId(alarm.id),
            notificationDetails: details,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(remindAt, tz.local),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
        return;
      }

      // Recurring: one weekly notification per active repeat day.
      for (var i = 0; i < alarm.repeatDays.length; i++) {
        if (!alarm.repeatDays[i]) continue;
        final next = _nextDateForDay(
          i,
          alarm.dateTime.hour,
          alarm.dateTime.minute,
        ).subtract(Duration(minutes: alarm.reminderMinutesBefore));
        await _plugin.zonedSchedule(
          id: _baseId(alarm.id) + i,
          notificationDetails: details,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(next, tz.local),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e, st) {
      debugPrint('[NotificationService] syncReminder failed: $e');
      AnalyticsService.trackError('NotificationService.syncReminder', e, st);
    }
  }

  /// Cancels every reminder notification associated with [alarmId].
  static Future<void> cancelReminder(String alarmId) async {
    try {
      final base = _baseId(alarmId);
      for (var i = 0; i < 7; i++) {
        await _plugin.cancel(id: base + i);
      }
    } catch (e, st) {
      debugPrint('[NotificationService] cancelReminder failed: $e');
      AnalyticsService.trackError('NotificationService.cancelReminder', e, st);
    }
  }

  /// Stable, non-negative notification id base for an alarm. Recurring alarms
  /// use base + dayIndex (0–6); the base leaves room for those 7 ids.
  static int _baseId(String alarmId) => (alarmId.hashCode & 0x7FFFFFF) * 8;

  /// Next [DateTime] (>= now) whose weekday matches [dayIndex] (0=Sun … 6=Sat)
  /// at [hour]:[minute].
  static DateTime _nextDateForDay(int dayIndex, int hour, int minute) {
    final now = DateTime.now();
    for (var add = 0; add < 8; add++) {
      final day = DateTime(now.year, now.month, now.day, hour, minute)
          .add(Duration(days: add));
      if (day.weekday % 7 == dayIndex && day.isAfter(now)) return day;
    }
    return DateTime(now.year, now.month, now.day, hour, minute)
        .add(const Duration(days: 7));
  }
}
