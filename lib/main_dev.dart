import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levio/app.dart';
import 'package:levio/firebase_options_dev.dart';
import 'features/subscription/services/superwall_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SuperwallService.configure();

  FirebaseFunctions.instance.useFunctionsEmulator('192.168.1.69', 5001);

  runApp(LevioApp(navigatorKey: _navigatorKey));
}
