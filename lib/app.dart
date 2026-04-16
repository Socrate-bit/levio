import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:levio/features/onboarding/screens/onboarding_screen.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import 'features/auth/cubit/auth_cubit.dart';
import 'features/alarms/cubit/alarm_cubit.dart';
import 'features/subscription/cubit/subscription_cubit.dart';
import 'features/alarms/cubit/alarm_state.dart';
import 'features/alarms/services/alarm_firestore_service.dart';
import 'features/alarms/services/alarm_service.dart';
import 'features/settings/cubit/settings_cubit.dart';
import 'features/settings/cubit/settings_state.dart';
import 'features/dismiss/screens/alarm_dismiss_screen.dart';
import 'features/dismiss/screens/math_dismiss_screen.dart';
import 'features/dismiss/screens/mission_sequence_screen.dart';
import 'features/dismiss/screens/photo_dismiss_screen.dart';
import 'features/dismiss/screens/shake_dismiss_screen.dart';
import 'features/dismiss/screens/simple_dismiss_screen.dart';
import 'features/dismiss/screens/speech_dismiss_screen.dart';
import 'features/dismiss/screens/squat_dismiss_screen.dart';
import 'features/missions/models/mission.dart';
import 'features/missions/models/mission_config.dart';
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
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => AuthCubit()..loadUserType()),
        BlocProvider(
          lazy: false,
          create: (context) => SubscriptionCubit(
            alarmCubit: context.read<AlarmCubit>(),
            authCubit: context.read<AuthCubit>(),
          ),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Levio',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: widget.navigatorKey,
          builder: (context, child) {
            final unfocused = GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: child,
            );
            final isSubscribed =
                context.watch<SubscriptionCubit>().state.isActive;
            if (isSubscribed) return unfocused;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () =>
                  Superwall.shared.registerPlacement('app_start'),
              child: unfocused,
            );
          },
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
              final label = args['label'] ?? 'Alarm #1';

              // Fetch mission config from Firestore asynchronously
              return MaterialPageRoute(
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

        if (missions.length == 1) {
          return buildDismissScreen(
            config: missions.first,
            alarmId: alarmId,
            nativeAlarmId: nativeAlarmId,
            alarmLabel: label,
          );
        }

        // Multiple missions → sequence screen
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
  bool manageAlarm = true,
  bool isPreview = false,
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
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.math:
      return MathDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        alarmLabel: alarmLabel,
        difficulty: config.mathDifficulty ?? MathDifficulty.easy,
        problemCount: config.mathProblemCount ?? 3,
        onComplete: onComplete,
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.skyPhoto:
    case MissionType.makeBed:
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
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
    case MissionType.affirmation:
      return SpeechDismissScreen(
        alarmId: alarmId,
        nativeAlarmId: nativeAlarmId,
        missionType: missionType,
        alarmLabel: alarmLabel,
        selectedAffirmations: config.selectedAffirmations,
        onComplete: onComplete,
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
        manageAlarm: manageAlarm,
        isPreview: isPreview,
      );
  }
}
