import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:levio/app.dart';
import 'package:levio/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/superwall_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SuperwallService.configure();

  // Check if user is logged in and has completed onboarding
  final showOnboarding =
      !AuthService.isLoggedIn || !(await AuthService.checkOnboardingComplete());

  runApp(LevioApp(navigatorKey: _navigatorKey, showOnboarding: showOnboarding));
}
