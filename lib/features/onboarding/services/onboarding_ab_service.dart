import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../subscription/services/analytics_service.dart';
import '../onboarding_config.dart';

/// Resolves launch-time onboarding config from Firestore `settings/app_settings`.
///
/// - `ratio_ab` (0–100): percentage of users sent to the new v2 funnel. The
///   decision is re-rolled on every launch (no local persistence) and pushed to
///   Mixpanel as a user property for segmentation.
/// - `beta_phone` (bool): gates the beta phone-number collection step.
///
/// Both are read from a single doc fetch to avoid extra round-trips.
class OnboardingAbService {
  static const _userProperty = 'onboarding_variant';
  static const _defaultUseV2 = true; // matches current shipping behavior

  /// Resolves the funnel + beta flags from a single `settings/app_settings`
  /// read, publishes them to [useOnboardingV2] / [betaPhoneEnabled], and pushes
  /// the variant to Mixpanel. Runs in the background at startup so it never
  /// blocks launch; the v2 start screen renders meanwhile and AuthWrapper swaps
  /// to v1 if this resolves there. Re-rolled every launch — not persisted.
  static Future<void> resolveVariant() async {
    var useV2 = _defaultUseV2;
    var betaPhone = false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_settings')
          .get()
          .timeout(const Duration(seconds: 4)); // never hang startup
      final data = doc.data();
      useV2 = _decideFromRatio(data?['ratio_ab']);
      betaPhone = data?['beta_phone'] as bool? ?? false;
    } catch (e, st) {
      debugPrint('[OnboardingAbService] resolveVariant failed: $e');
      AnalyticsService.trackError('OnboardingAbService.resolveVariant', e, st);
    }

    // Publish so AuthWrapper swaps into the chosen funnel and the phone step
    // shows/hides accordingly.
    useOnboardingV2.value = useV2;
    betaPhoneEnabled.value = betaPhone;

    // Always push the chosen variant as a user property.
    await AnalyticsService.setUserProperty(_userProperty, useV2 ? 'v2' : 'v1');
  }

  /// Weights a coin flip by `ratio_ab`. Falls back to the current shipping
  /// default when the value is missing or not a number.
  static bool _decideFromRatio(Object? ratioRaw) {
    if (ratioRaw is! num) return _defaultUseV2;
    final ratio = ratioRaw.clamp(0, 100).toInt();
    if (ratio >= 100) return true;
    if (ratio <= 0) return false;
    return Random().nextInt(100) < ratio; // weighted by the ratio
  }
}
