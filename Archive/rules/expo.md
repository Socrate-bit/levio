---
description: Expo React Native conventions
globs: "apps/app/**"
---

## Uniwind & Layout

- Never put className on Animated components — wrap layout in plain View
- Uniwind classes silently drop on `Animated.View` and `Animated.createAnimatedComponent()` on web
- Always structure as: `<AnimatedComponent><View className="...layout">{children}</View></AnimatedComponent>`
- Use inline styles only for non-layout properties on animated elements

## Liquid Glass (iOS 26+)

- Use `NativeTabs` from `expo-router/unstable-native-tabs` for native iOS/Android
- Platform-split: `NativeTabs` on native, regular `Tabs` from `expo-router` on web
- Use `sf` prop on `Icon` for iOS tab icons with `sf-symbols-typescript`
- Use `androidSrc` with `VectorIcon` for Android fallback

## GlassView & GlassCard

- Always check `isGlassEffectAPIAvailable()` before rendering glass components
- GlassView provides its own translucent background — do not add opaque `bg-*` classes
- Use conditional styling: `glassAvailable ? "border border-white/20" : "bg-[#F8F9FA] dark:bg-[#1A1A2E] border border-[#E5E7EB]"`
- Import `glassAvailable` flag from `components/ui/GlassCard.tsx`
- Wrap grouped GlassView elements in `GlassContainer` with `spacing` prop for Liquid Glass merge effect

## Typography

- Font family: Outfit_400Regular, Outfit_600SemiBold, Outfit_700Bold
- Use inline styles for font sizing, not StyleSheet.create

## Imports

- tRPC: `import { trpc } from '@/lib/trpc'`
- Auth: `import { useSession } from '@/lib/auth'`
- Never add `.js` extension on imports — Metro resolves automatically. Ex: `import { foo } from '@/constants/colors'`

## Error Handling

- ErrorBoundary required per major screen (DeckScreen, ReviewScreen, OnboardingScreen, SettingsScreen)
- Fallback UI must be cohesive with design system, never blank screen
- Capture errors to PostHog: `posthog.capture('error_boundary_triggered', { screen, error })`
- Provide recovery action (retry, back, refresh)

## Tone

- Always use "tu" (informal you) — never "vous" — in user-facing copy
- Examples: "Entre ton email", "Tes decks", "Connecte-toi"
