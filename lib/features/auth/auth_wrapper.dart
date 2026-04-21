import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_service.dart';
import 'screens/welcome_screen.dart';
import '../alarms/cubit/alarm_cubit.dart';
import '../onboarding/cubit/onboarding_cubit.dart';
import '../onboarding/cubit/onboarding_state.dart';
import '../onboarding/screens/onboarding_screen.dart';
import '../settings/cubit/settings_cubit.dart';
import '../subscription/cubit/subscription_cubit.dart';
import '../subscription/screens/app_gate_wrapper.dart';

/// Top-level reactive auth gate. Routes between WelcomeScreen,
/// OnboardingScreen, and AppGateWrapper based on FirebaseAuth state,
/// the in-memory OnboardingCubit.isInProgress flag, and the Firestore
/// users/{uid}/meta/onboarding.onboardingComplete flag.
///
/// Routing matrix:
/// - Unauthed + !isInProgress → WelcomeScreen
/// - Unauthed + isInProgress (Build Plan tapped) → OnboardingScreen
/// - Authed + (isInProgress OR !onboardingComplete) → OnboardingScreen
/// - Authed + !isInProgress + onboardingComplete → AppGateWrapper
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
        final user = snap.data;
        final isAuth = user != null;

        debugPrint(
          '[AuthWrapper] auth state → ${isAuth ? 'signed in (uid=${user.uid})' : 'signed out'}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AlarmCubit>().printActiveAlarms();
          context.read<SettingsCubit>().printSharedPrefs();
        });

        return BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, ob) {
            if (!isAuth) {
              // Logout / fresh install — wipe device-local state.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<SubscriptionCubit>().resetIdentity();
                context.read<SettingsCubit>().clearAll();
                context.read<AlarmCubit>().cancelAllNative();
              });
              return ob.isInProgress
                  ? const OnboardingScreen()
                  : const WelcomeScreen();
            }

            context.read<SubscriptionCubit>().identifyUser(user.uid);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AlarmCubit>().loadAlarm();
            });

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('meta')
                  .doc('onboarding')
                  .snapshots(),
              builder: (context, doc) {
                if (doc.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final complete =
                    doc.data?.data()?['onboardingComplete'] == true;
                if (ob.isInProgress || !complete) {
                  return const OnboardingScreen();
                }
                return AppGateWrapper(navigatorKey: navigatorKey);
              },
            );
          },
        );
      },
    );
  }
}
