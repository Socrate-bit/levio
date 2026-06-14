import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levio/app.dart';
import 'package:levio/features/subscription/services/analytics_service.dart';
import 'package:levio/firebase_options.dart';
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

  runApp(LevioApp(navigatorKey: _navigatorKey));
}
