import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/features/auth/auth_wrapper.dart';
import 'package:levio/features/subscription/services/analytics_service.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/shared/services/analytics_route_observer.dart';
import 'package:mixpanel_flutter_session_replay/mixpanel_flutter_session_replay.dart';

import 'features/alarms/cubit/alarm_cubit.dart';
import 'features/alarms/cubit/alarm_state.dart';
import 'features/alarms/services/alarm_firestore_service.dart';
import 'features/alarms/services/alarm_service.dart';
import 'features/dismiss/screens/alarm_dismiss_screen.dart';
import 'features/dismiss/screens/breathing_mission_screen.dart';
import 'features/dismiss/screens/gratefulness_dismiss_screen.dart';
import 'features/dismiss/screens/math_dismiss_screen.dart';
import 'features/dismiss/screens/meditation_dismiss_screen.dart';
import 'features/dismiss/screens/mission_sequence_screen.dart';
import 'features/dismiss/screens/photo_dismiss_screen.dart';
import 'features/dismiss/screens/routine_dismiss_screen.dart';
import 'features/dismiss/screens/shake_dismiss_screen.dart';
import 'features/dismiss/screens/simple_dismiss_screen.dart';
import 'features/dismiss/screens/speech_dismiss_screen.dart';
import 'features/dismiss/screens/squat_dismiss_screen.dart';
import 'features/missions/models/mission.dart';
import 'features/missions/models/mission_config.dart';
import 'features/onboarding/cubit/onboarding_cubit.dart';
import 'features/screentime/cubit/screentime_cubit.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/settings/cubit/settings_state.dart';
import 'features/subscription/cubit/subscription_cubit.dart';
import 'shared/theme/app_theme.dart';

class LevioApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const LevioApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => AlarmCubit()),
        BlocProvider(create: (_) => SubscriptionCubit()),
        BlocProvider(create: (_) => OnboardingCubit()),
        BlocProvider(create: (_) => ScreenTimeCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => ScreenUtilInit(
          designSize: const Size(414, 896),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) => MixpanelSessionReplayWidget(
            instance: AnalyticsService.sessionReplay,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Levio',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              // User-selected language wins; otherwise follow the device.
              locale: settings.locale ?? DevicePreview.locale(context),
              navigatorKey: navigatorKey,
              navigatorObservers: [
                AnalyticsRouteObserver(),
                DismissRouteObserver(),
              ],
              builder: (context, child) => DevicePreview.appBuilder(
                context,
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: child,
                ),
              ),
              initialRoute: '/',
              routes: {'/': (_) => AuthWrapper(navigatorKey: navigatorKey)},
              onGenerateRoute: (settings) {
                if (settings.name == '/alarm-dismiss') {
                  final args = settings.arguments as Map<String, String>;
                  final alarmId = args['alarmId']!;
                  final nativeAlarmId = args['nativeAlarmId'] ?? alarmId;
                  final label = args['label'] ?? 'Alarm #1';

                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => _DismissLoader(
                      alarmId: alarmId,
                      nativeAlarmId: nativeAlarmId,
                      label: label,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Fetches alarm entry from Firestore, then routes to the appropriate dismiss
/// screen based on mission config.
class _DismissLoader extends StatelessWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String label;

  const _DismissLoader({
    required this.alarmId,
    required this.nativeAlarmId,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppAlarmEntry?>(
      future: AlarmFirestoreService.getAlarm(alarmId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = snapshot.data;
        final missions = entry?.missions ?? const [];

        if (missions.isEmpty) {
          return SimpleDismissScreen(
            alarmId: alarmId,
            nativeAlarmId: nativeAlarmId,
            alarmLabel: label,
          );
        }

        // Always route through MissionSequenceScreen so the start screen is
        // shown even for single-mission alarms.
        return MissionSequenceScreen(
          missions: missions,
          alarmId: alarmId,
          nativeAlarmId: nativeAlarmId,
          alarmLabel: label,
        );
      },
    );
  }
}

/// Builds a dismiss screen for a single [MissionConfig].
Widget buildDismissScreen({
  required MissionConfig config,
  required String alarmId,
  required String nativeAlarmId,
  required String alarmLabel,
  VoidCallback? onComplete,
  VoidCallback? onProgress,
  bool manageAlarm = true,
  bool isPreview = false,
  ValueChanged<String>? onPhotoTargetChosen,
}) {
  // Resolve random mission type
  var missionType = config.type;
  if (missionType == MissionType.random) {
    final pool = (config.randomPool != null && config.randomPool!.isNotEmpty)
        ? config.randomPool!
        : MissionType.values
              .where((t) => t != MissionType.none && t != MissionType.random)
              .toList();
    missionType = (List<MissionType>.from(pool)..shuffle()).first;
  }

  switch (missionType) {
    case MissionType.none:
      return SimpleDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
      );
    case MissionType.shakePhone:
      return ShakeDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        target: config.repCount ?? 15,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.math:
      return MathDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        difficulty: config.mathDifficulty ?? MathDifficulty.medium,
        problemCount: config.mathProblemCount ?? 3,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.skyPhoto:
    case MissionType.makeBed:
    case MissionType.bedPhoto:
    case MissionType.objectHunt:
    case MissionType.petHunt:
    case MissionType.natureHunt:
    case MissionType.touchGrass:
      return PhotoDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        missionType: missionType,
        alarmLabel: alarmLabel,
        selectedItems: config.selectedItems,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
        onTargetChosen: onPhotoTargetChosen,
      );
    case MissionType.affirmation:
      return SpeechDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        missionType: missionType,
        alarmLabel: alarmLabel,
        selectedAffirmations: config.selectedAffirmations,
        affirmationCount: config.affirmationCount ?? 1,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.routine:
      return RoutineDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        items: config.selectedItems,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.squats:
      return SquatDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        repCount: config.repCount ?? 10,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.breathing:
      return BreathingMissionScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        rounds: config.breathingRounds ?? 3,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.gratefulness:
      return GratefulnessDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.meditation:
      return MeditationDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        minMinutes: config.meditationMinutes ?? 2,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.pushUps:
    default:
      return AlarmDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        repCount: config.repCount ?? 5,
        onComplete: onComplete,
        onProgress: onProgress,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
  }
}
