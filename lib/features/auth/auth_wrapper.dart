import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_service.dart';
import '../alarms/cubit/alarm_cubit.dart';
import '../onboarding/cubit/onboarding_cubit.dart';
import '../onboarding/cubit/onboarding_state.dart';
import '../onboarding/onboarding_config.dart';
import '../onboarding/screens/onboarding_screen.dart';
import '../onboarding/screens/onboarding_screen_v2.dart';
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
          buildWhen: (prev, curr) => prev.isInProgress != curr.isInProgress,
          builder: (context, ob) {
            if (!isAuth || ob.isInProgress) {
              return kUseOnboardingV2
                  ? const OnboardingScreenV2()
                  : const OnboardingScreen();
            }
            return AppGateWrapper(navigatorKey: widget.navigatorKey);
          },
        );
      },
    );
  }
}
