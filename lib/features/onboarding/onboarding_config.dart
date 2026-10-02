import 'package:flutter/foundation.dart';

/// Selects which onboarding funnel `AuthWrapper` shows.
///
/// `true`  → the redesigned v2 funnel (`OnboardingScreenV2`).
/// `false` → the original funnel (`OnboardingScreen`).
///
/// Defaults to `false` (v1) so users who start before the A/B value resolves,
/// or whose Firestore read fails, land on v1. `OnboardingAbService.resolveVariant()`
/// updates it in the background from the Firebase `ratio_ab` A/B rollout; the
/// value is read once when the user leaves the shared start screen.
final ValueNotifier<bool> useOnboardingV2 = ValueNotifier<bool>(false);

/// Gates the beta phone-number collection step (shown just before the paywall
/// in both onboarding funnels).
///
/// Driven by Firestore `settings/app_settings`.`beta_phone`. Defaults to `false`
/// so the step stays hidden until the flag is confirmed on;
/// `OnboardingAbService.resolveVariant()` updates it in the background at launch.
final ValueNotifier<bool> betaPhoneEnabled = ValueNotifier<bool>(false);

/// Shows the "Create your account" (Apple / Google / skip) step in both
/// onboarding funnels. When hidden, the anonymous account created on "Build my
/// plan" is kept and the onboarding is finalized when the user steps past it.
///
/// Driven by Firestore `settings/app_settings`.`show_signin_step`. Defaults to
/// `false` so the step stays hidden unless the flag is explicitly turned on.
final ValueNotifier<bool> showSignInStep = ValueNotifier<bool>(false);

/// Shows the two closing trial steps ("try Levio for free" + trial reminder)
/// in both onboarding funnels. When hidden, the onboarding finishes on the last
/// visible step and the Superwall paywall takes over.
///
/// Driven by Firestore `settings/app_settings`.`show_trial_steps`. Defaults to
/// `false` so the steps stay hidden unless the flag is explicitly turned on.
final ValueNotifier<bool> showTrialSteps = ValueNotifier<bool>(false);
