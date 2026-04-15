import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/features/onboarding/screens/onboarding_screen.dart';

import 'features/alarms/cubit/alarm_cubit.dart';
import 'features/alarms/cubit/alarm_state.dart';
import 'features/alarms/services/alarm_service.dart';
import 'features/settings/cubit/theme_cubit.dart';
import 'features/dismiss/screens/alarm_dismiss_screen.dart';
import 'features/dismiss/screens/math_dismiss_screen.dart';
import 'features/dismiss/screens/photo_dismiss_screen.dart';
import 'features/dismiss/screens/shake_dismiss_screen.dart';
import 'features/dismiss/screens/simple_dismiss_screen.dart';
import 'features/dismiss/screens/speech_dismiss_screen.dart';
import 'features/dismiss/screens/squat_dismiss_screen.dart';
import 'features/missions/models/mission.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/bottom_nav_shell.dart';

class LevioApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool showOnboarding;

  const LevioApp({
    super.key,
    required this.navigatorKey,
    this.showOnboarding = false,
  });

  @override
  State<LevioApp> createState() => _LevioAppState();
}

class _LevioAppState extends State<LevioApp> {
  @override
  void initState() {
    super.initState();
    AlarmService.listenForRing(widget.navigatorKey);
  }

  @override
  void dispose() {
    AlarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AlarmCubit()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Levio',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          navigatorKey: widget.navigatorKey,
          initialRoute: '/',
          routes: {
            '/': (_) => widget.showOnboarding
                ? const OnboardingScreen()
                : const BottomNavShell(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/alarm-dismiss') {
              final args = settings.arguments as Map<String, String>;
              final alarmId = args['alarmId']!;
              final nativeAlarmId = args['nativeAlarmId'] ?? alarmId;
              final challengeStr = args['challenge'] ?? 'pushUps';
              final label = args['label'] ?? 'Alarm #1';
              final mathDiffStr = args['mathDifficulty'] ?? 'easy';
              final customObj = args['customObject'];
              var mission = missionTypeFromString(challengeStr);
              if (mission == MissionType.random) {
                final randomPool = [
                  MissionType.pushUps,
                  MissionType.squats,
                  MissionType.shakePhone,
                  MissionType.math,
                  MissionType.skyPhoto,
                  MissionType.makeBed,
                  MissionType.objectHunt,
                  MissionType.petHunt,
                  MissionType.natureHunt,
                  MissionType.touchGrass,
                  MissionType.bibleVerse,
                  MissionType.affirmation,
                ];
                mission = (randomPool..shuffle()).first;
              }
              final mathDiff = MathDifficulty.values.firstWhere(
                (d) => d.name == mathDiffStr,
                orElse: () => MathDifficulty.easy,
              );

              switch (mission) {
                case MissionType.none:
                  return MaterialPageRoute(
                    builder: (_) => SimpleDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      alarmLabel: label,
                    ),
                  );
                case MissionType.shakePhone:
                  return MaterialPageRoute(
                    builder: (_) => ShakeDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      alarmLabel: label,
                    ),
                  );
                case MissionType.math:
                  return MaterialPageRoute(
                    builder: (_) => MathDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      alarmLabel: label,
                      difficulty: mathDiff,
                    ),
                  );
                case MissionType.skyPhoto:
                case MissionType.makeBed:
                case MissionType.objectHunt:
                case MissionType.petHunt:
                case MissionType.natureHunt:
                case MissionType.touchGrass:
                  return MaterialPageRoute(
                    builder: (_) => PhotoDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      missionType: mission,
                      alarmLabel: label,
                      customObject: customObj?.isNotEmpty == true
                          ? customObj
                          : null,
                    ),
                  );
                case MissionType.bibleVerse:
                case MissionType.affirmation:
                  return MaterialPageRoute(
                    builder: (_) => SpeechDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      missionType: mission,
                      alarmLabel: label,
                    ),
                  );
                case MissionType.squats:
                  return MaterialPageRoute(
                    builder: (_) => SquatDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      alarmLabel: label,
                    ),
                  );

                case MissionType.pushUps:
                default:
                  return MaterialPageRoute(
                    builder: (_) => AlarmDismissScreen(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      alarmLabel: label,
                    ),
                  );
              }
            }
            return null;
          },
        ),
      ),
    );
  }
}
