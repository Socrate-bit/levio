import 'package:flutter/foundation.dart';

/// Selects which onboarding funnel `AuthWrapper` shows.
///
/// `true`  → the redesigned v2 funnel (`OnboardingScreenV2`).
/// `false` → the original funnel (`OnboardingScreen`).
///
/// Defaults to `true` so the v2 start screen renders immediately at launch with
/// no startup block. `OnboardingAbService.resolveVariant()` updates it in the
/// background from the Firebase `ratio_ab` A/B rollout; `AuthWrapper` listens
/// and swaps funnels reactively while the user is still on the start screen.
final ValueNotifier<bool> useOnboardingV2 = ValueNotifier<bool>(true);
