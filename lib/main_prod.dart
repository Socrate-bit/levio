import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levio/app.dart';
import 'package:levio/features/subscription/services/analytics_service.dart';
import 'package:levio/firebase_options.dart';
import 'package:levio/shared/services/branch_service.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService.init();

  // Match paywall locale to the device locale (e.g. "en_US", "fr_FR").
  final options = SuperwallOptions()..localeIdentifier = Platform.localeName;
  Superwall.configure('pk_H0nPpphGj3awY7K1T2ngX', options: options);

  // Initialize Branch (requests ATT, then inits + listens for sessions) after
  // the first frame. iOS only shows the ATT prompt when the app is in an
  // active foreground state, so deferring to post-frame guarantees the prompt
  // actually appears instead of silently resolving to notDetermined/denied.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(BranchService.init());
  });

  runApp(LevioApp(navigatorKey: _navigatorKey));
}
