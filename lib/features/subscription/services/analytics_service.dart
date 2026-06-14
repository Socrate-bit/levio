import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:mixpanel_flutter_session_replay/mixpanel_flutter_session_replay.dart';

class AnalyticsService {
  static const _token = 'e800cac11637a25d3fe360def7c1a667';
  static Mixpanel? _mixpanel;

  // Session replay instance, passed to MixpanelSessionReplayWidget in app.dart.
  static MixpanelSessionReplay? sessionReplay;

  // Initialize the Mixpanel SDK + session replay. Call once at app startup.
  static Future<void> init() async {
    try {
      _mixpanel = await Mixpanel.init(_token, trackAutomaticEvents: true);
      await _initSessionReplay();
    } catch (e) {
      debugPrint('[AnalyticsService] init failed: $e');
    }
  }

  static Future<void> _initSessionReplay() async {
    try {
      final distinctId = await _mixpanel?.getDistinctId();
      if (distinctId == null) return;
      final result = await MixpanelSessionReplay.initialize(
        token: _token,
        distinctId: distinctId,
        options: const SessionReplayOptions(autoRecordSessionsPercent: 100.0),
      );
      if (result.success) sessionReplay = result.instance;
    } catch (e) {
      debugPrint('[AnalyticsService] session replay init failed: $e');
    }
  }

  static Future<void> identify(String uid) async {
    try {
      await _mixpanel?.identify(uid);
      sessionReplay?.identify(uid);
    } catch (e) {
      debugPrint('[AnalyticsService] identify failed: $e');
    }
  }

  static Future<void> reset() async {
    try {
      await _mixpanel?.reset();
      // Re-associate session replay with the new anonymous distinct id.
      final distinctId = await _mixpanel?.getDistinctId();
      if (distinctId != null) sessionReplay?.identify(distinctId);
    } catch (e) {
      debugPrint('[AnalyticsService] reset failed: $e');
    }
  }

  static Future<void> capture(
    String event, [
    Map<String, Object>? props,
  ]) async {
    try {
      _mixpanel?.track(event, properties: props);
    } catch (e) {
      debugPrint('[AnalyticsService] capture $event failed: $e');
    }
  }

  // Track a screen view from the navigator observer.
  static Future<void> trackScreen(String name) async {
    await capture(screenView, {'screen': name});
  }

  // Auth
  static const signIn = 'sign_in';
  static const signOut = 'sign_out';
  static const accountDeleted = 'account_deleted';

  // Alarms
  static const alarmCreated = 'alarm_created';
  static const alarmUpdated = 'alarm_updated';
  static const alarmDeleted = 'alarm_deleted';
  static const alarmStopped = 'alarm_stopped';
  static const alarmToggled = 'alarm_toggled';

  // Ring / Dismiss
  static const alarmRingStarted = 'alarm_ring_started';
  static const alarmRingDismissed = 'alarm_ring_dismissed';

  // Missions
  static const missionStarted = 'mission_started';
  static const missionCompleted = 'mission_completed';
  static const missionFailed = 'mission_failed';

  // Sessions
  static const sessionSaved = 'session_saved';

  // Subscription
  static const subscriptionActivated = 'subscription_activated';
  static const subscriptionLost = 'subscription_lost';

  // Referral
  static const referralRedeemAttempt = 'referral_redeem_attempt';
  static const referralRedeemSuccess = 'referral_redeem_success';
  static const referralRedeemFailed = 'referral_redeem_failed';

  // Streak / Badge
  static const streakMilestone = 'streak_milestone';
  static const badgeEarned = 'badge_earned';

  // Onboarding
  static const onboardingStep = 'onboarding_step';

  // Navigation
  static const navTabSelected = 'nav_tab_selected';
  static const screenView = 'screen_view';

  // Settings
  static const settingsNotificationsToggled = 'settings_notifications_toggled';
  static const settingsDarkModeToggled = 'settings_dark_mode_toggled';
  static const settingsKeepAlarmToggled = 'settings_keep_alarm_toggled';
}
