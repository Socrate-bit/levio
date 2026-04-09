import 'package:flutter/material.dart';

import 'screens/alarm_dismiss_screen.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for a ringing alarm before the widget tree is built (cold start).
  final ringingAlarmId = await AlarmService.getRingingAlarm();

  runApp(LevioApp(
    navigatorKey: _navigatorKey,
    ringingAlarmId: ringingAlarmId,
  ));
}

class LevioApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String? ringingAlarmId;

  const LevioApp({
    super.key,
    required this.navigatorKey,
    this.ringingAlarmId,
  });

  @override
  State<LevioApp> createState() => _LevioAppState();
}

class _LevioAppState extends State<LevioApp> {
  @override
  void initState() {
    super.initState();
    AlarmService.listenForRing(widget.navigatorKey);

    // If the app was opened from a ringing alarm (cold start), navigate after
    // the first frame so the navigator is fully initialised.
    if (widget.ringingAlarmId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamed(
          '/alarm-dismiss',
          arguments: widget.ringingAlarmId,
        );
      });
    }
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
          final alarmId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => AlarmDismissScreen(alarmId: alarmId),
          );
        }
        return null;
      },
    );
  }
}
