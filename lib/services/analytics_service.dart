import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  static Future<void> identify(String uid) async {
    try {
      await Posthog().identify(userId: uid);
    } catch (e) {
      debugPrint('[AnalyticsService] identify failed: $e');
    }
  }

  static Future<void> reset() async {
    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('[AnalyticsService] reset failed: $e');
    }
  }

  static Future<void> capture(String event, [Map<String, Object>? props]) async {
    try {
      await Posthog().capture(eventName: event, properties: props);
    } catch (e) {
      debugPrint('[AnalyticsService] capture $event failed: $e');
    }
  }

  // Auth
  static const signIn = 'sign_in';
  static const signOut = 'sign_out';

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

  // Settings
  static const settingsNotificationsToggled = 'settings_notifications_toggled';
  static const settingsDarkModeToggled = 'settings_dark_mode_toggled';
  static const settingsKeepAlarmToggled = 'settings_keep_alarm_toggled';
}
