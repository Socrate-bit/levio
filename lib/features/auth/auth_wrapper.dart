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
class AuthWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AuthWrapper({super.key, required this.navigatorKey});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Cached onboarding-doc stream keyed by uid. Rebuilding the stream on
  // every parent rebuild would flash ConnectionState.waiting and reset
  // OnboardingScreen state on every tap.
  String? _onboardingUid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _onboardingStream;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _streamFor(String uid) {
    if (_onboardingUid != uid || _onboardingStream == null) {
      _onboardingUid = uid;
      _onboardingStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('onboarding')
          .snapshots();
    }
    return _onboardingStream!;
  }

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
          if (!mounted) return;
          context.read<AlarmCubit>().printActiveAlarms();
          context.read<SettingsCubit>().printSharedPrefs();
        });

        return BlocBuilder<OnboardingCubit, OnboardingState>(
          buildWhen: (prev, next) => prev.isInProgress != next.isInProgress,
          builder: (context, ob) {
            if (!isAuth) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
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
              if (!mounted) return;
              context.read<AlarmCubit>().loadAlarm();
            });

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _streamFor(user.uid),
              builder: (context, doc) {
                // Don't flash a loading screen while the onboarding doc
                // resolves — just show onboarding. AuthWrapper swaps to
                // AppGateWrapper reactively once the doc arrives with
                // onboardingComplete=true and isInProgress is false.
                final complete =
                    doc.data?.data()?['onboardingComplete'] == true;
                if (ob.isInProgress || !complete) {
                  return const OnboardingScreen();
                }
                return AppGateWrapper(navigatorKey: widget.navigatorKey);
              },
            );
          },
        );
      },
    );
  }
}
