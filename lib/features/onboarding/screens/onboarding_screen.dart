import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../missions/models/mission.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../data/mission_explanations.dart';
import '../widgets/day_picker_step.dart';
import '../widgets/energy_chart.dart';
import '../widgets/info_step.dart';
import '../widgets/loading_step.dart';
import '../widgets/mission_picker_step.dart';
import '../widgets/morning_plan_step.dart';
import '../widgets/notification_step.dart';
import '../widgets/paywall_step.dart';
import '../widgets/rating_step.dart';
import '../widgets/referral_step.dart';
import '../widgets/sign_in_step.dart';
import '../widgets/signature_step.dart';
import '../widgets/sound_picker_step.dart';
import '../widgets/speedometer_chart.dart';
import '../widgets/timeline_comparison.dart';
import '../widgets/trial_reminder_step.dart';
import '../widgets/survey_step.dart';
import '../widgets/time_picker_step.dart';
import '../widgets/welcome_step.dart';

const _totalPages = 36;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    final wasOnWelcome = _currentPage == 0;
    setState(() => _currentPage = page);
    // PageView doesn't contain the welcome page, so its index = page - 1.
    if (page >= 1) {
      if (wasOnWelcome) {
        // PageView just entered the tree — wait one frame for it to attach.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(0);
        });
      } else {
        await _pageController.animateToPage(
          page - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _next() => _goToPage(_currentPage + 1);

  Future<void> _handleContinuePress(
    OnboardingState state,
    OnboardingCubit cubit,
  ) async {
    // Referral step: validate any entered code before advancing.
    if (_currentPage == 27) {
      final code = state.referralCode.trim();
      FocusScope.of(context).unfocus();
      if (code.isNotEmpty &&
          state.referralStatus != ReferralStatus.valid) {
        await cubit.submitReferralCode();
        if (!mounted) return;
        if (cubit.state.referralStatus != ReferralStatus.valid) return;
      }
    }
    // Rating step triggers in-app review.
    if (_currentPage == 28) {
      InAppReview.instance.requestReview();
    }
    _next();
  }

  void _back() {
    if (_currentPage > 0 && _currentPage != 31) _goToPage(_currentPage - 1);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool _canContinue(OnboardingState state) {
    switch (_currentPage) {
      case 0: // welcome — has its own button
        return true;
      case 1:
        return state.surveyAnswers.containsKey('morningPerson');
      case 2:
        return state.surveyAnswers.containsKey('ageRange');
      case 3:
        return state.surveyAnswers.containsKey('gender');
      case 4:
        return state.surveyAnswers.containsKey('bedProblem');
      case 5:
        return state.surveyAnswers.containsKey('firstThought');
      case 6: // info
        return true;
      case 7:
        return state.surveyAnswers.containsKey('alarmCount');
      case 8:
        return state.surveyAnswers.containsKey('oneAlarmWakeUp');
      case 9:
        return state.surveyAnswers.containsKey('turnOffSleep');
      case 10: // info
        return true;
      case 11:
        return state.surveyAnswers.containsKey('feelSettingAlarm');
      case 12:
        return state.surveyAnswers.containsKey('feelAfterWaking');
      case 13:
        return state.surveyAnswers.containsKey('timeToAwake');
      case 14: // info (biology)
      case 15: // info (speedometer)
      case 16: // time picker - usual wake time
      case 17: // time picker - ideal wake time
      case 18: // info - target
      case 19: // info - quote
        return true;
      case 20: // mission picker — always has a default mission
      case 21: // info - mission
      case 22: // time picker - alarm
      case 23: // day picker
      case 24: // sound picker
        return true;
      case 25:
        return state.surveyAnswers.containsKey('alarmDuringMission');
      case 26:
        return state.surveyAnswers.containsKey('heardFrom');
      case 27: // referral — blocked when entered code is invalid/exhausted
        return state.referralStatus != ReferralStatus.checking &&
            state.referralStatus != ReferralStatus.invalid &&
            state.referralStatus != ReferralStatus.exhausted;
      case 28: // rating
      case 29: // notification — has own buttons
      case 30: // signature — has own button
      case 31: // loading — auto-advances
      case 32: // morning plan summary
      case 33: // sign in — has own buttons
      case 34: // paywall — has own button
      case 35: // trial reminder — has own button
        return true;
      default:
        return true;
    }
  }

  // Pages that handle their own navigation (no shared Continue button)
  bool _hasOwnNavigation(int page) =>
      page == 0 ||
      page == 29 ||
      page == 30 ||
      page == 31 ||
      page == 33 ||
      page == 34 ||
      page == 35;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          final c = AppColors.of(context);
          final l10n = AppLocalizations.of(context);

          return Scaffold(
            backgroundColor: c.background,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Progress bar + back — always in tree to keep
                  // PageView height stable; invisible on welcome & last page.
                  Opacity(
                    opacity:
                        (_currentPage > 0 && _currentPage < _totalPages - 1)
                        ? 1.0
                        : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          if (_currentPage > 0 && _currentPage != 31)
                            GestureDetector(
                              onTap: withHaptic(_back),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c.card,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 20,
                                  color: c.textPrimary,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _currentPage / (_totalPages - 1),
                                backgroundColor: c.separator,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.orange,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: _currentPage == 0
                        ? WelcomeStep(
                            onBuildPlan: () {
                              cubit.startOnboarding();
                              _next();
                            },
                            onSignIn: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const _StandaloneSignInScreen(),
                                ),
                              );
                            },
                          )
                        : PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              SurveyStep(
                                question: l10n.onboardingMorningPerson,
                                options: [
                                  l10n.onboardingYes,
                                  l10n.onboardingNotYet,
                                ],
                                selectedOption:
                                    state.surveyAnswers['morningPerson'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('morningPerson', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingAgeRange,
                                options: const [
                                  '13-17',
                                  '18-24',
                                  '25-34',
                                  '35-44',
                                  '45-54',
                                  '55+',
                                ],
                                selectedOption: state.surveyAnswers['ageRange'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('ageRange', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingDescribesYou,
                                options: [
                                  l10n.onboardingMale,
                                  l10n.onboardingFemale,
                                  l10n.onboardingOther,
                                ],
                                selectedOption: state.surveyAnswers['gender'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('gender', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingKeepsInBed,
                                options: [
                                  l10n.onboardingPhoneScrolling,
                                  l10n.onboardingSnoozeLoop,
                                  l10n.onboardingSleepThrough,
                                  l10n.onboardingStayInBed,
                                ],
                                selectedOption:
                                    state.surveyAnswers['bedProblem'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('bedProblem', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingFirstThought,
                                options: [
                                  l10n.onboardingImUp,
                                  l10n.onboardingFiveMore,
                                  l10n.onboardingSetAnother,
                                  l10n.onboardingWhyDidI,
                                ],
                                selectedOption:
                                    state.surveyAnswers['firstThought'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('firstThought', v),
                              ),
                              // 6: Info - Energy levels
                              InfoStep(
                                title: l10n.onboardingGetsYouOut,
                                imagePlaceholder: const EnergyChart(),
                                bodyText: l10n.onboardingAvoidGroggy,
                              ),
                              // 7-9: More surveys
                              SurveyStep(
                                question: l10n.onboardingHowManyAlarms,
                                options: [
                                  l10n.onboardingOne,
                                  l10n.onboardingTwoThree,
                                  l10n.onboardingFourPlus,
                                ],
                                selectedOption:
                                    state.surveyAnswers['alarmCount'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('alarmCount', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingOneAlarmWakeUp,
                                options: [
                                  l10n.onboardingYes,
                                  l10n.onboardingSometimes,
                                  l10n.onboardingNo,
                                ],
                                selectedOption:
                                    state.surveyAnswers['oneAlarmWakeUp'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('oneAlarmWakeUp', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingTurnOffGoBack,
                                options: [
                                  l10n.onboardingOften,
                                  l10n.onboardingSometimes,
                                  l10n.onboardingRarely,
                                  l10n.onboardingNever,
                                ],
                                selectedOption:
                                    state.surveyAnswers['turnOffSleep'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('turnOffSleep', v),
                              ),
                              // 10: Info - One alarm one mission
                              InfoStep(
                                title: l10n.onboardingOneAlarmOneMission,
                                imagePlaceholder: const TimelineComparison(),
                              ),
                              // 11-13: More surveys
                              SurveyStep(
                                question: l10n.onboardingFeelSettingAlarm,
                                options: [
                                  l10n.onboardingMotivated,
                                  l10n.onboardingAnxiousSleep,
                                  l10n.onboardingDefeated,
                                  l10n.onboardingNeutral,
                                ],
                                selectedOption:
                                    state.surveyAnswers['feelSettingAlarm'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('feelSettingAlarm', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingFeelAfterWaking,
                                options: [
                                  l10n.onboardingReadyToGo,
                                  l10n.onboardingGroggy,
                                  l10n.onboardingAnxiousStressed,
                                  l10n.onboardingNeutral,
                                ],
                                selectedOption:
                                    state.surveyAnswers['feelAfterWaking'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('feelAfterWaking', v),
                              ),
                              SurveyStep(
                                question: l10n.onboardingHowLongAwake,
                                options: [
                                  l10n.onboardingInstantly,
                                  l10n.onboardingTenFifteen,
                                  l10n.onboardingThirtyPlus,
                                ],
                                selectedOption:
                                    state.surveyAnswers['timeToAwake'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('timeToAwake', v),
                              ),
                              // 14: Info - Biology not laziness
                              InfoStep(
                                title: l10n.onboardingBiologyTitle,
                                centerTitle: true,
                                imagePlaceholder: const Text(
                                  '🧬',
                                  style: TextStyle(fontSize: 80),
                                ),
                                bodyText: l10n.onboardingBiologyBody,
                              ),
                              // 15: Info - Speedometer
                              InfoStep(
                                title: l10n.onboarding5xFaster,
                                imagePlaceholder: const SpeedometerChart(),
                              ),
                              // 16: Time picker - usual wake time
                              TimePickerStep(
                                title:
                                    'What time do you usually get out of bed?',
                                subtitle:
                                    'This helps us set a realistic first target.',
                                time: state.usualWakeTime,
                                onTimeChanged: cubit.setUsualWakeTime,
                              ),
                              // 17: Time picker - ideal wake time
                              TimePickerStep(
                                title: 'What time do you want to\nbe up?',
                                subtitle: 'Your ideal daily wake up time.',
                                time: state.idealWakeTime,
                                onTimeChanged: cubit.setIdealWakeTime,
                              ),
                              // 18: Info - Target time with delta
                              Builder(
                                builder: (context) {
                                  final target = state.targetTime;
                                  final delta = state.wakeTimeDeltaMinutes;
                                  final monthHours = (delta * 30 / 60).round();
                                  return InfoStep(
                                    title: '',
                                    centerTitle: true,
                                    imagePlaceholder: Column(
                                      children: [
                                        Text(
                                          'Waking up at ${_formatTime(target)} is your target.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: c.textPrimary,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (delta > 0) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            '+$delta minutes every morning',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '+$monthHours hours this month',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // 19: Info - Quote
                              InfoStep(
                                title: '',
                                centerTitle: true,
                                imagePlaceholder: Column(
                                  children: [
                                    Text(
                                      '66',
                                      style: TextStyle(
                                        fontSize: 48,
                                        color: c.separator,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'If you win\nthe morning,\nyou win the day.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: c.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '— Tim Ferriss',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 20: Mission picker
                              MissionPickerStep(
                                selectedMission: state.selectedMission,
                                onSelected: cubit.setMission,
                              ),
                              // 21: Info - Mission explanation
                              Builder(
                                builder: (context) {
                                  final mission = state.selectedMission;
                                  final info = missionInfoFor(mission);
                                  final explanations = getMissionExplanations(
                                    l10n,
                                  );
                                  final explanation =
                                      explanations[mission] ??
                                      explanations[MissionType.pushUps]!;
                                  return InfoStep(
                                    title: explanation['title']!,
                                    imagePlaceholder: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: info.iconBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        info.icon,
                                        color: info.iconColor,
                                        size: 56,
                                      ),
                                    ),
                                    subtitle: explanation['subtitle'],
                                    bodyText: explanation['body'],
                                  );
                                },
                              ),
                              // 22: Alarm time picker
                              Builder(
                                builder: (context) {
                                  final alarmTime = state.alarmTime;
                                  final l10n = AppLocalizations.of(context);
                                  return TimePickerStep(
                                    title: l10n.onboardingTimePickerTitle,
                                    subtitle:
                                        l10n.onboardingTimePickerSubtitle(_formatTime(alarmTime)),
                                    time: alarmTime,
                                    onTimeChanged: cubit.setAlarmTime,
                                  );
                                },
                              ),
                              // 23: Day picker
                              DayPickerStep(
                                repeatDays: state.repeatDays,
                                onToggle: cubit.toggleDay,
                              ),
                              // 24: Sound picker
                              SoundPickerStep(
                                selectedId: state.soundId,
                                onSelected: cubit.setSound,
                              ),
                              // 25: Alarm during mission
                              SurveyStep(
                                question: l10n.onboardingAlarmDuringMission,
                                options: [
                                  l10n.onboardingAlarmKeepRinging,
                                  l10n.onboardingAlarmStopRinging,
                                ],
                                selectedOption:
                                    state.surveyAnswers['alarmDuringMission'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('alarmDuringMission', v),
                              ),
                              // 26: Where heard about us
                              SurveyStep(
                                question: l10n.onboardingWhereHeard,
                                options: [
                                  l10n.onboardingYouTube,
                                  l10n.onboardingFacebook,
                                  l10n.onboardingTwitter,
                                  l10n.onboardingReddit,
                                  l10n.onboardingAppStore,
                                  l10n.onboardingFriendFamily,
                                  l10n.onboardingOther,
                                ],
                                icons: const [
                                  Icons.play_circle_filled,
                                  Icons.facebook,
                                  Icons.close, // X logo approximation
                                  Icons.reddit,
                                  Icons.storefront,
                                  Icons.people,
                                  Icons.chat_bubble,
                                ],
                                selectedOption:
                                    state.surveyAnswers['heardFrom'],
                                onSelected: (v) =>
                                    cubit.answerSurvey('heardFrom', v),
                              ),
                              // 27: Referral code
                              ReferralStep(
                                code: state.referralCode,
                                status: state.referralStatus,
                                onCodeChanged: cubit.setReferralCode,
                              ),
                              // 28: Rating
                              const RatingStep(),
                              // 29: Notification permission
                              NotificationStep(onNext: _next),
                              // 30: Signature
                              SignatureStep(
                                alarmTimeText: _formatTime(state.alarmTime),
                                onCommit: _next,
                              ),
                              // 31: Loading
                              LoadingStep(
                                onComplete: () {
                                  if (mounted) _next();
                                },
                              ),
                              // 32: Morning plan summary
                              MorningPlanStep(
                                alarmTime: state.alarmTime,
                                mission: state.selectedMission,
                                soundId: state.soundId,
                                repeatDays: state.repeatDays,
                              ),
                              // 33: Sign in — saves alarm + refreshes user type
                              SignInStep(
                                onSkip: () async {
                                  final alarmCubit = context.read<AlarmCubit>();
                                  final subCubit =
                                      context.read<SubscriptionCubit>();
                                  await cubit.completeOnboarding(
                                    alarmCubit,
                                    subCubit,
                                  );
                                  if (mounted) _next();
                                },
                                onSignInComplete: () async {
                                  final alarmCubit = context.read<AlarmCubit>();
                                  final subCubit =
                                      context.read<SubscriptionCubit>();
                                  await cubit.completeOnboarding(
                                    alarmCubit,
                                    subCubit,
                                  );
                                  if (mounted) _next();
                                },
                              ),
                              // 34: Paywall - Try for free
                              PaywallStep(onContinue: _next),
                              // 35: Trial reminder — finishes onboarding;
                              // AuthWrapper reactively swaps to AppGateWrapper.
                              TrialReminderStep(
                                onContinue: cubit.finishOnboarding,
                              ),
                            ],
                          ),
                  ),

                  // Bottom button (hidden for pages with own nav)
                  if (!_hasOwnNavigation(_currentPage))
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _canContinue(state)
                                ? withHaptic(() {
                                    _handleContinuePress(state, cubit);
                                  })
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.textPrimary,
                              foregroundColor: c.card,
                              disabledBackgroundColor: c.separator,
                              disabledForegroundColor: c.textSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              _currentPage == 22
                                  ? l10n.onboardingSetAlarmFor(
                                      _formatTime(state.alarmTime),
                                    )
                                  : l10n.onboardingContinue,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
  }
}

class _StandaloneSignInScreen extends StatelessWidget {
  const _StandaloneSignInScreen();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.of(context).pop()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SignInStep(
                title: 'Welcome back',
                subtitle: 'Sign in to restore your plan.',
                onSkip: () => Navigator.of(context).pop(),
                // After sign-in, pop. AuthWrapper reactively routes to
                // AppGateWrapper because isInProgress is still false.
                onSignInComplete: () => Navigator.of(context).pop(),
                showSkip: false,
                blockNewAccounts: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
