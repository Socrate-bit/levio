import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../subscription/services/analytics_service.dart';
import '../onboarding_config.dart';

/// Resolves which onboarding funnel a user sees (A/B test).
///
/// The rollout is driven by Firestore `settings/app_settings`.`ratio_ab` — the
/// percentage (0–100) of users sent to the new v2 funnel. The decision is made
/// once, persisted locally so the user never flips funnels across cold starts,
/// and pushed to Mixpanel as a user property for segmentation.
class OnboardingAbService {
  static const _prefsKey = 'onboarding_variant'; // stored as 'v2' | 'v1'
  static const _userProperty = 'onboarding_variant';
  static const _defaultUseV2 = true; // matches current shipping behavior

  /// Resolves the funnel once, publishes it to [useOnboardingV2], persists it,
  /// and pushes the variant to Mixpanel. Runs in the background at startup so it
  /// never blocks launch; the v2 start screen renders meanwhile and AuthWrapper
  /// swaps to v1 if this resolves there.
  static Future<void> resolveVariant() async {
    final prefs = await SharedPreferences.getInstance();

    // Sticky: reuse a prior decision so the user keeps the same funnel.
    bool useV2;
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      useV2 = stored == 'v2';
    } else {
      useV2 = await _decideFromRatio();
      await prefs.setString(_prefsKey, useV2 ? 'v2' : 'v1');
    }

    // Publish so AuthWrapper swaps into the chosen funnel.
    useOnboardingV2.value = useV2;

    // Always push the chosen variant as a user property.
    await AnalyticsService.setUserProperty(_userProperty, useV2 ? 'v2' : 'v1');
  }

  /// Reads `ratio_ab` and weights a coin flip by it. Falls back to the current
  /// shipping default on any failure (offline, missing doc/field, timeout).
  static Future<bool> _decideFromRatio() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_settings')
          .get()
          .timeout(const Duration(seconds: 4)); // never hang startup
      final ratioRaw = doc.data()?['ratio_ab'];
      if (ratioRaw is! num) return _defaultUseV2;
      final ratio = ratioRaw.clamp(0, 100).toInt();
      if (ratio >= 100) return true;
      if (ratio <= 0) return false;
      return Random().nextInt(100) < ratio; // weighted by the ratio
    } catch (e, st) {
      debugPrint('[OnboardingAbService] resolveVariant failed: $e');
      AnalyticsService.trackError('OnboardingAbService.resolveVariant', e, st);
      return _defaultUseV2;
    }
  }
}
