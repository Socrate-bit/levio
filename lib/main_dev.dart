import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levio/app.dart';
import 'package:levio/features/alarms/services/notification_service.dart';
import 'package:levio/features/subscription/services/analytics_service.dart';
import 'package:levio/firebase_options_dev.dart';
import 'package:levio/shared/services/branch_service.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AnalyticsService.init();
  await NotificationService.init();

  // Match paywall locale to the device locale (e.g. "en_US", "fr_FR").
  final options = SuperwallOptions()..localeIdentifier = Platform.localeName;
  Superwall.configure('pk_H0nPpphGj3awY7K1T2ngX', options: options);

  // FirebaseFunctions.instance.useFunctionsEmulator('192.168.1.69', 5001);

  // Initialize Branch (requests ATT, then inits + listens for sessions) after
  // the first frame. iOS only shows the ATT prompt when the app is in an
  // active foreground state, so deferring to post-frame guarantees the prompt
  // actually appears instead of silently resolving to notDetermined/denied.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(BranchService.init());
  });

  runApp(
    // DevicePreview(
    //   enabled: !kReleaseMode,
    //   data: DevicePreviewData(
    //     deviceIdentifier: Devices.ios.iPhoneSE.identifier.toString(),
    //     isFrameVisible: true,
    //   ),
    //   builder: (context) =>
    LevioApp(navigatorKey: _navigatorKey),
    // ),
  );
}
