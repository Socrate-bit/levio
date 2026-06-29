/// Selects which onboarding funnel `AuthWrapper` shows.
///
/// `true`  → the redesigned v2 funnel (`OnboardingScreenV2`).
/// `false` → the original funnel (`OnboardingScreen`).
///
/// Kept as a single source-of-truth const so the two funnels can be A/B tested
/// later by backing this with a Mixpanel/remote flag without touching call sites.
const bool kUseOnboardingV2 = true;
