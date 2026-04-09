import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/alarm_dismiss_screen.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/photo_dismiss_screen.dart';
import 'screens/shake_dismiss_screen.dart';
import 'screens/speech_dismiss_screen.dart';
import 'services/alarm_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Requires GoogleService-Info.plist (iOS) / google-services.json (Android)
  // and optionally firebase_options.dart from `flutterfire configure`.
  await Firebase.initializeApp();

  // Check for a ringing alarm before the widget tree is built (cold start).
  final ringingAlarm = await AlarmService.getRingingAlarm();

  runApp(LevioApp(
    navigatorKey: _navigatorKey,
    ringingAlarm: ringingAlarm,
  ));
}

class LevioApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Map<String, String>? ringingAlarm;

  const LevioApp({
    super.key,
    required this.navigatorKey,
    this.ringingAlarm,
  });

  @override
  State<LevioApp> createState() => _LevioAppState();
}

class _LevioAppState extends State<LevioApp> {
  @override
  void initState() {
    super.initState();
    AlarmService.listenForRing(widget.navigatorKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.ringingAlarm != null) {
        // Alarm was actively ringing at cold start.
        widget.navigatorKey.currentState?.pushNamed(
          '/alarm-dismiss',
          arguments: widget.ringingAlarm,
        );
      } else {
        // Check whether the user tapped "Do push-up" from the notification
        // banner while the app was killed (alarm is now snoozed, not alerting).
        AlarmService.checkAndNavigate(widget.navigatorKey);
      }
    });
  }

  @override
  void dispose() {
    AlarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/alarms': (_) => const AlarmListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/alarm-dismiss') {
          final args = settings.arguments as Map<String, String>;
          final alarmId = args['alarmId']!;
          if (args['challenge'] == 'shake') {
            return MaterialPageRoute(
              builder: (_) => ShakeDismissScreen(alarmId: alarmId),
            );
          }
          if (args['challenge'] == 'photo') {
            return MaterialPageRoute(
              builder: (_) => PhotoDismissScreen(alarmId: alarmId),
            );
          }
          if (args['challenge'] == 'speech') {
            return MaterialPageRoute(
              builder: (_) => SpeechDismissScreen(alarmId: alarmId),
            );
          }
          return MaterialPageRoute(
            builder: (_) => AlarmDismissScreen(alarmId: alarmId),
          );
        }
        return null;
      },
    );
  }
}
