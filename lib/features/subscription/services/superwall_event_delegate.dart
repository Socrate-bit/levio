import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../../shared/services/branch_service.dart';

/// Listens to Superwall transaction events to fire Branch conversion events.
/// Set once at startup via [Superwall.shared.setDelegate].
///
/// Only [handleSuperwallEvent] carries logic; the remaining abstract members
/// are no-ops since we only care about transaction events here. This delegate
/// runs alongside the [Superwall.shared.subscriptionStatus] stream consumed by
/// SubscriptionCubit (independent channels) — START_TRIAL still fires there.
class SuperwallEventDelegate extends SuperwallDelegate {
  @override
  void handleSuperwallEvent(SuperwallEventInfo eventInfo) {
    // subscriptionStart = a paid subscription began WITHOUT a free trial.
    // (freeTrialStart is the trial case, reported via START_TRIAL instead.)
    if (eventInfo.event.type == EventType.subscriptionStart) {
      BranchService.trackPurchase();
    }
  }

  @override
  void subscriptionStatusDidChange(SubscriptionStatus newValue) {}

  @override
  void handleCustomPaywallAction(String name) {}

  @override
  void willDismissPaywall(PaywallInfo paywallInfo) {}

  @override
  void willPresentPaywall(PaywallInfo paywallInfo) {}

  @override
  void didDismissPaywall(PaywallInfo paywallInfo) {}

  @override
  void didPresentPaywall(PaywallInfo paywallInfo) {}

  @override
  void paywallWillOpenURL(Uri url) {}

  @override
  void paywallWillOpenDeepLink(Uri url) {}

  @override
  void handleLog(String level, String scope, String? message,
      Map<dynamic, dynamic>? info, String? error) {}

  @override
  void handleSuperwallDeepLink(Uri fullURL, List<String> pathComponents,
      Map<String, String> queryParameters) {}
}
