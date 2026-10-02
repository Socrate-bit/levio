import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_service.dart';
import '../subscription/services/analytics_service.dart';
import '../alarms/cubit/alarm_cubit.dart';
import '../onboarding/cubit/onboarding_cubit.dart';
import '../onboarding/cubit/onboarding_state.dart';
import '../onboarding/onboarding_config.dart';
import '../onboarding/screens/onboarding_screen.dart';
import '../onboarding/screens/onboarding_screen_v2.dart';
import '../onboarding/screens/onboarding_start_screen.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../settings/cubit/settings_cubit.dart';
import '../subscription/cubit/subscription_cubit.dart';
import '../subscription/screens/app_gate_wrapper.dart';

/// Top-level reactive auth gate. Routes between OnboardingScreen and
/// AppGateWrapper based on FirebaseAuth state and OnboardingCubit progress.
///
/// - Not auth → side effects (clear settings, cancel native alarms) → onboarding.
/// - Auth + onboarding in progress → onboarding (the anonymous account is
///   created on "Build my plan", so the in-flow user is signed in throughout;
///   the flag is persisted so a relaunch mid-onboarding resumes it).
/// - Auth + not in progress → AppGateWrapper.
class AuthWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AuthWrapper({super.key, required this.navigatorKey});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Tracks the last handled auth state so side effects fire only on an actual
  // transition — not on every rebuild (locale/theme changes rebuild this tree).
  bool? _lastIsAuth;

  // The funnel the user is committed to once they leave the start screen. Read
  // once from the background-resolved A/B value (`useOnboardingV2`) and then
  // fixed, so the back arrow can't re-resolve or swap funnels. Null until the
  // user first taps "Build my plan".
  bool? _committedV2;

  // Whether the user has left the shared start screen and entered a funnel. The
  // back arrow on the funnel's first step flips this back to false, returning to
  // the start screen while keeping the committed variant.
  bool _started = false;

  // Commits the A/B direction (once) and enters the chosen funnel. Re-entering
  // after a back keeps the same direction and skips the v2 routine seeding.
  void _startOnboarding() {
    if (_committedV2 == null) {
      final useV2 = useOnboardingV2.value;
      _committedV2 = useV2;
      final cubit = context.read<OnboardingCubit>();
      cubit.startOnboarding();
      if (useV2) {
        // Seed v2 routine defaults: pre-select the first 3 steps of each
        // catalog (wake-up + sleep).
        cubit.setWakeRoutine(routineWakePresetSteps.take(3).toList());
        cubit.setRelaxingActivities(routineNightPresetSteps.take(3).toList());
      }
    }
    setState(() => _started = true);
    _ensureAccount();
  }

  // Creates the anonymous account up front so everything the onboarding saves
  // has a uid. No-op when already signed in. On failure (e.g. offline) the
  // onboarding retries when it is finalized.
  Future<void> _ensureAccount() async {
    try {
      await AuthService.signInAnonymously();
    } catch (e, st) {
      debugPrint('[AuthWrapper] anonymous sign-in failed: $e');
      AnalyticsService.trackError('AuthWrapper._ensureAccount', e, st);
    }
  }

  void _exitToStart() => setState(() => _started = false);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final isAuth = snap.data != null;

        // Auth side effects — run once per auth state change, not on every
        // onboarding step / locale / theme rebuild.
        if (isAuth != _lastIsAuth) {
          _lastIsAuth = isAuth;
          if (!isAuth) {
            // Returning to a signed-out state (sign out / delete account) must
            // land on the shared start screen, not whatever funnel page the
            // previous session committed to.
            _started = false;
            _committedV2 = null;
          }
          final uid = snap.data?.uid;
          debugPrint(
            '[AuthWrapper] auth state → ${isAuth ? 'signed in (uid=$uid)' : 'signed out'}',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<AlarmCubit>().printActiveAlarms();
            context.read<SettingsCubit>().printSharedPrefs();
            if (!isAuth) {
              context.read<SubscriptionCubit>().resetIdentity();
              context.read<SettingsCubit>().clearAll();
              context.read<AlarmCubit>().cancelAllNative();
            } else {
              context.read<SubscriptionCubit>().identifyUser(uid!);
              context.read<AlarmCubit>().loadAlarm();
            }
          });
        }

        return BlocBuilder<OnboardingCubit, OnboardingState>(
          buildWhen: (prev, curr) =>
              prev.isInProgress != curr.isInProgress ||
              prev.isRestored != curr.isRestored,
          builder: (context, ob) {
            // Wait for the persisted in-progress flag before routing a
            // signed-in user, so a relaunch mid-onboarding never flashes the app.
            if (isAuth && !ob.isRestored && !ob.isInProgress) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!isAuth || ob.isInProgress) {
              // Shared start screen for both variants. The A/B direction is
              // committed when the user leaves it and stays fixed afterwards, so
              // the back arrow returns here without re-resolving or swapping.
              if (!_started) {
                return OnboardingStartScreen(onStart: _startOnboarding);
              }
              return _committedV2!
                  ? OnboardingScreenV2(onExitToStart: _exitToStart)
                  : OnboardingScreen(onExitToStart: _exitToStart);
            }
            return AppGateWrapper(navigatorKey: widget.navigatorKey);
          },
        );
      },
    );
  }
}
