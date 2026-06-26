import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../missions/models/mission.dart';
import '../../settings/cubit/settings_cubit.dart';
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

  // Local notifiers for the three time pickers. Updated on every scroll tick
  // without touching the Bloc, then flushed to the cubit on Continue.
  late final ValueNotifier<TimeOfDay> _usualWakeNotifier;
  late final ValueNotifier<TimeOfDay> _idealWakeNotifier;
  late final ValueNotifier<TimeOfDay> _alarmTimeNotifier;

  @override
  void initState() {
    super.initState();
    _usualWakeNotifier = ValueNotifier(const TimeOfDay(hour: 7, minute: 30));
    _idealWakeNotifier = ValueNotifier(const TimeOfDay(hour: 7, minute: 0));
    _alarmTimeNotifier = ValueNotifier(const TimeOfDay(hour: 7, minute: 0));
  }

  @override
  void dispose() {
    _usualWakeNotifier.dispose();
    _idealWakeNotifier.dispose();
    _alarmTimeNotifier.dispose();
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
    // Flush time picker local state to cubit before advancing.
    if (_currentPage == 15) {
      cubit.setUsualWakeTime(_usualWakeNotifier.value);
    } else if (_currentPage == 16) {
      cubit.setIdealWakeTime(_idealWakeNotifier.value);
      // Sync alarm time notifier so page 21 opens at the ideal wake time.
      _alarmTimeNotifier.value = _idealWakeNotifier.value;
    } else if (_currentPage == 21) {
      cubit.setAlarmTime(_alarmTimeNotifier.value);
    }
    // Referral step: validate any entered code before advancing.
    if (_currentPage == 26) {
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
    if (_currentPage > 0 &&
        _currentPage != 31 &&
        _currentPage != 32 &&
        _currentPage != 34 &&
        _currentPage != 35) {
      _goToPage(_currentPage - 1);
    }
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
      case 15: // time picker - usual wake time
      case 16: // time picker - ideal wake time
      case 17: // info - target
      case 18: // info - quote
        return true;
      case 19: // mission picker — always has a default mission
      case 20: // info - mission
      case 21: // time picker - alarm
      case 22: // day picker
      case 23: // sound picker
        return true;
      case 24:
        return state.keepAlarmDuringMission != null;
      case 25:
        return state.surveyAnswers.containsKey('heardFrom');
      case 26: // referral — blocked when entered code is invalid/exhausted
        return state.referralStatus != ReferralStatus.checking &&
            state.referralStatus != ReferralStatus.invalid &&
            state.referralStatus != ReferralStatus.exhausted;
      case 27: // info (speedometer)
        return true;
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
                        (_currentPage > 0 &&
                                _currentPage < _totalPages - 1 &&
                                _currentPage != 32)
                            ? 1.0
                            : 0.0,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                      child: Row(
                        children: [
                          if (_currentPage > 0 &&
                              _currentPage != 31 &&
                              _currentPage != 32 &&
                              _currentPage != 34 &&
                              _currentPage != 35)
                            GestureDetector(
                              onTap: withHaptic(_back),
                              child: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: c.card,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 20.sp,
                                  color: c.textPrimary,
                                ),
                              ),
                            )
                          else
                            SizedBox(width: 32.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
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
                                imagePlaceholder: Text(
                                  '🧬',
                                  style: TextStyle(fontSize: 80.sp),
                                ),
                                bodyText: l10n.onboardingBiologyBody,
                              ),
                              // 15: Time picker - usual wake time
                              TimePickerStep(
                                title: l10n.onboardingUsualWakeTimeTitle,
                                subtitle: l10n.onboardingUsualWakeTimeSubtitle,
                                notifier: _usualWakeNotifier,
                              ),
                              // 16: Time picker - ideal wake time
                              TimePickerStep(
                                title: l10n.onboardingIdealWakeTimeTitle,
                                subtitle: l10n.onboardingIdealWakeTimeSubtitle,
                                notifier: _idealWakeNotifier,
                              ),
                              // 17: Info - Target time with delta
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
                                          l10n.onboardingTargetWakeTime(
                                            _formatTime(target),
                                          ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 28.sp,
                                            fontWeight: FontWeight.bold,
                                            color: c.textPrimary,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (delta > 0) ...[
                                          SizedBox(height: 16.h),
                                          Text(
                                            l10n.onboardingDeltaPerMorning(delta),
                                            style: TextStyle(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            l10n.onboardingDeltaPerMonth(monthHours),
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // 18: Info - Quote
                              InfoStep(
                                title: '',
                                centerTitle: true,
                                imagePlaceholder: Column(
                                  children: [
                                    Text(
                                      '66',
                                      style: TextStyle(
                                        fontSize: 48.sp,
                                        color: c.separator,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      l10n.onboardingQuoteWinMorning,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        color: c.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      l10n.onboardingQuoteWinMorningAuthor,
                                      style: TextStyle(
                                        fontSize: 17.sp,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 19: Mission picker
                              MissionPickerStep(
                                selectedMission: state.selectedMission,
                                onSelected: cubit.setMission,
                              ),
                              // 20: Info - Mission explanation
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
                                      width: 120.w,
                                      height: 120.h,
                                      decoration: BoxDecoration(
                                        color: info.iconBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        info.icon,
                                        color: info.iconColor,
                                        size: 56.sp,
                                      ),
                                    ),
                                    subtitle: explanation['subtitle'],
                                    bodyText: explanation['body'],
                                  );
                                },
                              ),
                              // 21: Alarm time picker
                              TimePickerStep(
                                title: l10n.onboardingTimePickerTitle,
                                subtitleBuilder: (t) =>
                                    l10n.onboardingTimePickerSubtitle(
                                        _formatTime(t)),
                                notifier: _alarmTimeNotifier,
                              ),
                              // 22: Day picker
                              DayPickerStep(
                                repeatDays: state.repeatDays,
                                onToggle: cubit.toggleDay,
                              ),
                              // 23: Sound picker
                              SoundPickerStep(
                                selectedId: state.soundId,
                                onSelected: cubit.setSound,
                              ),
                              // 24: Alarm during mission
                              Builder(
                                builder: (context) {
                                  final keepLabel =
                                      l10n.onboardingAlarmKeepRinging;
                                  final stopLabel =
                                      l10n.onboardingAlarmStopRinging;
                                  final keep = state.keepAlarmDuringMission;
                                  return SurveyStep(
                                    question:
                                        l10n.onboardingAlarmDuringMission,
                                    options: [keepLabel, stopLabel],
                                    selectedOption: keep == null
                                        ? null
                                        : (keep ? keepLabel : stopLabel),
                                    onSelected: (v) => cubit
                                        .setKeepAlarmDuringMission(
                                            v == keepLabel),
                                  );
                                },
                              ),
                              // 25: Where heard about us
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
                              // 26: Referral code
                              ReferralStep(
                                code: state.referralCode,
                                status: state.referralStatus,
                                onCodeChanged: cubit.setReferralCode,
                              ),
                              // 27: Info - Speedometer
                              InfoStep(
                                title: l10n.onboarding5xFaster,
                                imagePlaceholder: const SpeedometerChart(),
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
                                title: l10n.onboardingSignInCreateTitle,
                                subtitle:
                                    l10n.onboardingSignInCreateSubtitle,
                                onSkip: () async {
                                  final alarmCubit = context.read<AlarmCubit>();
                                  final subCubit =
                                      context.read<SubscriptionCubit>();
                                  final settingsCubit =
                                      context.read<SettingsCubit>();
                                  await cubit.completeOnboarding(
                                    alarmCubit,
                                    subCubit,
                                    settingsCubit,
                                  );
                                  if (mounted) _next();
                                },
                                onSignInComplete: () async {
                                  final alarmCubit = context.read<AlarmCubit>();
                                  final subCubit =
                                      context.read<SubscriptionCubit>();
                                  final settingsCubit =
                                      context.read<SettingsCubit>();
                                  await cubit.completeOnboarding(
                                    alarmCubit,
                                    subCubit,
                                    settingsCubit,
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
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56.h,
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
                                borderRadius: BorderRadius.circular(28.r),
                              ),
                            ),
                            child: ValueListenableBuilder<TimeOfDay>(
                              valueListenable: _alarmTimeNotifier,
                              builder: (_, alarmTime, _) => Text(
                                _currentPage == 21
                                    ? l10n.onboardingSetAlarmFor(
                                        _formatTime(alarmTime),
                                      )
                                    : l10n.onboardingContinue,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.of(context).pop()),
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20.sp,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SignInStep(
                title: l10n.onboardingSignInTitle,
                subtitle: l10n.onboardingSignInSubtitle,
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
