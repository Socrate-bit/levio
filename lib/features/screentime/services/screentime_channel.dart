import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../subscription/services/analytics_service.dart';
import '../models/screentime_schedule.dart';

/// Dart bridge to the native iOS Screen Time implementation
/// (`ios/Runner/LevioScreenTime.swift`). Mirrors the AlarmKit channel pattern.
///
/// The blocked-app *selection* is opaque (FamilyControls tokens) and lives
/// natively in the shared App Group — Dart only ever learns the selection
/// count. Schedules + the master enabled flag are pushed down via
/// [applySchedules]; the native DeviceActivityMonitor extension owns applying
/// and clearing the shield at window boundaries.
class ScreenTimeChannel {
  static const _method = MethodChannel('levio/screentime');
  static const _events = EventChannel('levio/screentime/events');

  /// 'approved' | 'denied' | 'notDetermined'. Returns 'denied' on platforms
  /// without Screen Time (e.g. older iOS, Android).
  static Future<String> authorizationStatus() async {
    try {
      return await _method.invokeMethod<String>('authorizationStatus') ??
          'notDetermined';
    } on PlatformException catch (e, st) {
      debugPrint('[ScreenTimeChannel] authorizationStatus failed: ${e.message}');
      AnalyticsService.trackError('ScreenTimeChannel.authorizationStatus', e, st);
      return 'notDetermined';
    } on MissingPluginException {
      return 'denied';
    }
  }

  /// Requests FamilyControls individual authorization. Returns true if granted.
  static Future<bool> requestAuthorization() async {
    try {
      return await _method.invokeMethod<bool>('requestAuthorization') ?? false;
    } on PlatformException catch (e, st) {
      debugPrint('[ScreenTimeChannel] requestAuthorization failed: ${e.message}');
      AnalyticsService.trackError('ScreenTimeChannel.requestAuthorization', e, st);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Presents the native FamilyActivityPicker. Resolves with the new selection
  /// count once the user saves.
  static Future<int> pickApps() async {
    try {
      return await _method.invokeMethod<int>('pickApps') ?? 0;
    } on PlatformException catch (e, st) {
      debugPrint('[ScreenTimeChannel] pickApps failed: ${e.message}');
      AnalyticsService.trackError('ScreenTimeChannel.pickApps', e, st);
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Current number of selected apps + categories persisted natively.
  static Future<int> selectedAppCount() async {
    try {
      return await _method.invokeMethod<int>('selectedAppCount') ?? 0;
    } on PlatformException catch (e, st) {
      debugPrint('[ScreenTimeChannel] selectedAppCount failed: ${e.message}');
      AnalyticsService.trackError('ScreenTimeChannel.selectedAppCount', e, st);
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Pushes the master flag + full schedule list to native, which rebuilds its
  /// DeviceActivity monitoring and (re)applies / clears the shield to match the
  /// current window.
  static Future<void> applySchedules(
    bool enabled,
    List<ScreenTimeSchedule> schedules,
  ) async {
    try {
      await _method.invokeMethod('applySchedules', {
        'enabled': enabled,
        'schedules': schedules.map((s) => s.toJson()).toList(),
      });
    } on PlatformException catch (e, st) {
      debugPrint('[ScreenTimeChannel] applySchedules failed: ${e.message}');
      AnalyticsService.trackError('ScreenTimeChannel.applySchedules', e, st);
    } on MissingPluginException {
      // No native side (non-iOS) — no-op.
    }
  }

  static Stream<Map<Object?, Object?>> get events =>
      _events.receiveBroadcastStream().cast<Map<Object?, Object?>>();
}
