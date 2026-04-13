import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:levio/app.dart';
import 'package:levio/firebase_options_dev.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Anonymous auth — all Firestore data is scoped to this uid
  await AuthService.signInAnonymously();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

  runApp(LevioApp(navigatorKey: _navigatorKey, showOnboarding: !onboardingDone,));
}
