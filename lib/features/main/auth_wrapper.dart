import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/auth_service.dart';
import '../alarms/cubit/alarm_cubit.dart';
import '../onboarding/cubit/onboarding_cubit.dart';
import '../onboarding/cubit/onboarding_state.dart';
import '../onboarding/screens/onboarding_screen.dart';
import '../settings/cubit/settings_cubit.dart';
import 'app_gate_wrapper.dart';

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

        return BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, ob) {
            if (!isAuth) {
              // Logout / fresh install — wipe device-local state, then show
              // onboarding. Fire-and-forget; safe to call repeatedly.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<SettingsCubit>().clearAll();
                context.read<AlarmCubit>().cancelAllNative();
              });
              return const OnboardingScreen();
            }
            if (ob.isInProgress) {
              return const OnboardingScreen();
            }
            return AppGateWrapper(navigatorKey: navigatorKey);
          },
        );
      },
    );
  }
}
