import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_service.dart';
import '../alarms/cubit/alarm_cubit.dart';
import '../onboarding/cubit/onboarding_cubit.dart';
import '../onboarding/cubit/onboarding_state.dart';
import '../onboarding/screens/onboarding_screen.dart';
import '../settings/cubit/settings_cubit.dart';
import '../subscription/cubit/subscription_cubit.dart';
import '../subscription/screens/app_gate_wrapper.dart';

/// Top-level reactive auth gate. Routes between OnboardingScreen and
/// AppGateWrapper based on FirebaseAuth state and OnboardingCubit progress.
///
/// - Not auth → side effects (clear settings, cancel native alarms) → onboarding.
/// - Auth + onboarding in progress → onboarding (so the in-flow user keeps
///   seeing it across the auth flip during sign-in step).
/// - Auth + not in progress → AppGateWrapper.
class AuthWrapper extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AuthWrapper({super.key, required this.navigatorKey});

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

        // Debug dump on every auth state change.
        debugPrint(
          '[AuthWrapper] auth state → ${isAuth ? 'signed in (uid=${snap.data!.uid})' : 'signed out'}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AlarmCubit>().printActiveAlarms();
          context.read<SettingsCubit>().printSharedPrefs();
        });

        // Auth-only side effects — run once per auth state change, not on
        // every onboarding step rebuild.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isAuth) {
            context.read<SubscriptionCubit>().resetIdentity();
            context.read<SettingsCubit>().clearAll();
            context.read<AlarmCubit>().cancelAllNative();
          } else {
            context.read<SubscriptionCubit>().identifyUser(snap.data!.uid);
            context.read<AlarmCubit>().loadAlarm();
          }
        });

        return BlocBuilder<OnboardingCubit, OnboardingState>(
          buildWhen: (prev, curr) => prev.isInProgress != curr.isInProgress,
          builder: (context, ob) {
            if (!isAuth || ob.isInProgress) {
              return const OnboardingScreen();
            }
            return AppGateWrapper(navigatorKey: navigatorKey);
          },
        );
      },
    );
  }
}
