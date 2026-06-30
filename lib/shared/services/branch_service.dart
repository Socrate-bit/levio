import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';

/// Wraps the Branch SDK for install + event attribution (TikTok ads).
///
/// No deep-link routing is performed: the app always opens to its normal flow.
/// Branch is initialized only so installs and standard events (e.g. trial
/// start) are attributed to the campaign that drove them. All calls are guarded
/// so they never crash the app if init hasn't completed.
class BranchService {
  static bool _initialized = false;
  static StreamSubscription<Map<dynamic, dynamic>>? _sessionSub;

  /// Initializes Branch (install + event attribution).
  ///
  /// `ios/Runner/branch.json` sets `deferInitForPluginRuntime: true`, so the
  /// native SDK does NOT auto-initialize — it waits for [FlutterBranchSdk.init]
  /// below. The App Tracking Transparency prompt is requested separately, in
  /// context, via [requestTrackingAuthorization] (fired when the onboarding
  /// plan recap is revealed) rather than at launch.
  ///
  /// Safe to call once at startup; guarded against double-init.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      // Initialize the native Branch SDK (deferred via branch.json).
      await FlutterBranchSdk.init(enableLogging: kDebugMode);

      // Attach a session listener so Branch records the open and completes
      // attribution. Handler is intentionally minimal — no screen routing.
      _sessionSub = FlutterBranchSdk.listSession().listen(
        (_) {},
        onError: (Object e) => debugPrint('[BranchService] session error: $e'),
      );

      // TEMPORARY: validates the Branch integration end-to-end and prints the
      // result to the device console. REMOVE this line once integration is
      // confirmed passing (it must not ship to production).
      // FlutterBranchSdk.validateSDKIntegration();

      _initialized = true;
    } catch (e) {
      debugPrint('[BranchService] init failed: $e');
    }
  }

  /// Shows the iOS App Tracking Transparency prompt and waits for the user's
  /// response. Requested in context (when the onboarding plan recap is revealed)
  /// so the IDFA, if granted, becomes available to Branch. No-op on non-iOS.
  static Future<void> requestTrackingAuthorization() async {
    if (!Platform.isIOS) return;
    try {
      await FlutterBranchSdk.requestTrackingAuthorization();
    } catch (e) {
      debugPrint('[BranchService] ATT request failed: $e');
    }
  }

  /// Fires the Branch standard START_TRIAL event — the primary TikTok ad
  /// conversion. No-ops (with a log) if Branch hasn't initialized yet, so the
  /// caller never crashes.
  static void trackTrialStart() {
    if (!_initialized) {
      debugPrint('[BranchService] trackTrialStart skipped: not initialized');
      return;
    }
    try {
      // Standard event: this makes it eligible for TikTok conversion mapping,
      // but you must still map START_TRIAL -> TikTok's Start Trial event in
      // Branch's Events Config tab — it is NOT mapped automatically.
      final event = BranchEvent.standardEvent(BranchStandardEvent.START_TRIAL);
      FlutterBranchSdk.trackContentWithoutBuo(branchEvent: event);
    } catch (e) {
      debugPrint('[BranchService] trackTrialStart failed: $e');
    }
  }

  /// Fires the Branch standard COMPLETE_REGISTRATION event when onboarding
  /// finishes. No-ops (with a log) if Branch hasn't initialized yet.
  static void trackCompleteRegistration() {
    if (!_initialized) {
      debugPrint(
          '[BranchService] trackCompleteRegistration skipped: not initialized');
      return;
    }
    try {
      // Standard event: map COMPLETE_REGISTRATION -> TikTok's Complete
      // Registration in Branch's Events Config tab (not automatic).
      final event =
          BranchEvent.standardEvent(BranchStandardEvent.COMPLETE_REGISTRATION);
      FlutterBranchSdk.trackContentWithoutBuo(branchEvent: event);
    } catch (e) {
      debugPrint('[BranchService] trackCompleteRegistration failed: $e');
    }
  }

  /// Fires the Branch standard PURCHASE event for a real paid subscription
  /// (NOT a free trial — that is reported via [trackTrialStart]). No-ops (with
  /// a log) if Branch hasn't initialized yet.
  static void trackPurchase() {
    if (!_initialized) {
      debugPrint('[BranchService] trackPurchase skipped: not initialized');
      return;
    }
    try {
      // Standard event: map PURCHASE -> TikTok's Purchase in Branch's Events
      // Config tab (not automatic).
      final event = BranchEvent.standardEvent(BranchStandardEvent.PURCHASE);
      FlutterBranchSdk.trackContentWithoutBuo(branchEvent: event);
    } catch (e) {
      debugPrint('[BranchService] trackPurchase failed: $e');
    }
  }

  /// Cancels the session listener. Not normally needed (lives for app
  /// lifetime), provided for completeness.
  static Future<void> dispose() async {
    await _sessionSub?.cancel();
    _sessionSub = null;
  }
}
