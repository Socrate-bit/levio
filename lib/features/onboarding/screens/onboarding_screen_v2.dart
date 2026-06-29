import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/utils/haptic_utils.dart';

import '../../../shared/services/branch_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_barrier.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/services/alarm_channel.dart';
import '../../missions/models/mission.dart';
import '../../missions/widgets/mission_icon.dart';
import '../../missions/widgets/routine_picker_screen.dart';
import '../../screentime/cubit/screentime_cubit.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../data/mission_explanations.dart';
import '../widgets/day_picker_step.dart';
import '../widgets/energy_chart.dart';
import '../widgets/first_room_step.dart';
import '../widgets/info_step.dart';
import '../widgets/language_selector.dart';
import '../widgets/loading_step.dart';
import '../widgets/mission_picker_step.dart';
import '../widgets/morning_plan_step.dart';
import '../widgets/multi_select_step.dart';
import '../widgets/notification_step.dart';
import '../widgets/paywall_step.dart';
import '../widgets/rating_step.dart';
import '../widgets/referral_step.dart';
import '../widgets/relaxing_activities_step.dart';
import '../widgets/sign_in_step.dart';
import '../widgets/signature_step.dart';
import '../widgets/sound_picker_step.dart';
import '../widgets/speedometer_chart.dart';
import '../widgets/timeline_comparison.dart';
import '../widgets/time_picker_step.dart';
import '../widgets/trial_reminder_step.dart';
import '../widgets/survey_step.dart';

const _totalPages = 39;

/// Redesigned onboarding funnel (v2). Runs in parallel with the original
/// [OnboardingScreen]; which one shows is chosen by `useOnboardingV2` in
/// AuthWrapper. Reuses the v1 step widgets and the shared [OnboardingCubit].
class OnboardingScreenV2 extends StatefulWidget {
  /// Called when the user backs out of the first step. The welcome page is now
  /// the shared [OnboardingStartScreen] outside this funnel, so going back from
  /// the first step returns there rather than into the funnel.
  final VoidCallback? onExitToStart;

  const OnboardingScreenV2({super.key, this.onExitToStart});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final _pageController = PageController();
  // Starts at the first real step; the welcome page lives in the shared
  // OnboardingStartScreen, outside this funnel. PageView index = page - 1.
  int _currentPage = 1;
  bool _finalizing = false;

  late final ValueNotifier<TimeOfDay> _alarmTimeNotifier;
  late final ValueNotifier<TimeOfDay> _sleepTimeNotifier;
  late final ValueNotifier<TimeOfDay> _blockStartNotifier;

  @override
  void initState() {
    super.initState();
    _alarmTimeNotifier = ValueNotifier(const TimeOfDay(hour: 7, minute: 0));
    _sleepTimeNotifier = ValueNotifier(const TimeOfDay(hour: 22, minute: 30));
    _blockStartNotifier = ValueNotifier(const TimeOfDay(hour: 22, minute: 30));
  }

  @override
  void dispose() {
    _alarmTimeNotifier.dispose();
    _sleepTimeNotifier.dispose();
    _blockStartNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    final from = _currentPage;
    final wasOnWelcome = from == 0;
    setState(() => _currentPage = page);
    if (page >= 1) {
      if (wasOnWelcome) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(0);
        });
      } else if ((page - from).abs() > 1) {
        _pageController.jumpToPage(page - 1);
      } else {
        await _pageController.animateToPage(
          page - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Sleep-section pages are skipped based on the user's answers so navigation
  // and the progress bar treat the flow as if they don't exist.
  List<int> _visiblePages(OnboardingState s) {
    final pages = <int>[];
    for (var i = 0; i < _totalPages; i++) {
      // 23/24: bedtime picker + wind-down routine — only with a bedtime alarm.
      if ((i == 23 || i == 24) && s.wantsSleepAlarm != true) continue;
      // 27: block-start picker — only when blocking but no bedtime to derive it.
      if (i == 27 &&
          !(s.wantsScreenBlock == true && s.wantsSleepAlarm != true)) {
        continue;
      }
      pages.add(i);
    }
    return pages;
  }

  double _progressFraction(OnboardingState s) {
    final visible = _visiblePages(s);
    if (visible.length <= 1) return 0;
    final pos = visible.indexOf(_currentPage);
    return pos <= 0 ? 0 : pos / (visible.length - 1);
  }

  bool _isLastPage(OnboardingState s) => _currentPage == _visiblePages(s).last;

  void _next() {
    final visible = _visiblePages(context.read<OnboardingCubit>().state);
    final pos = visible.indexOf(_currentPage);
    if (pos >= 0 && pos < visible.length - 1) _goToPage(visible[pos + 1]);
  }

  void _back() {
    // Loading, plan recap, paywall, trial disallow going back.
    if (_currentPage == 29 ||
        _currentPage == 30 ||
        _currentPage == 37 ||
        _currentPage == 38) {
      return;
    }
    final visible = _visiblePages(context.read<OnboardingCubit>().state);
    final pos = visible.indexOf(_currentPage);
    if (pos > 0) {
      final target = visible[pos - 1];
      // Page 0 is the extracted welcome — backing out of the first step returns
      // to the shared start screen instead of into the funnel.
      if (target == 0) {
        widget.onExitToStart?.call();
      } else {
        _goToPage(target);
      }
    }
  }

  Future<void> _finalizeSignInStep() async {
    final cubit = context.read<OnboardingCubit>();
    final alarmCubit = context.read<AlarmCubit>();
    final subCubit = context.read<SubscriptionCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    final screenTimeCubit = context.read<ScreenTimeCubit>();
    setState(() => _finalizing = true);
    try {
      await cubit.completeOnboardingV2(
          alarmCubit, subCubit, settingsCubit, screenTimeCubit);
    } finally {
      if (mounted) {
        setState(() => _finalizing = false);
        _next();
      }
    }
  }

  Future<void> _handleContinuePress(
    OnboardingState state,
    OnboardingCubit cubit,
  ) async {
    // Ask for AlarmKit authorization right before the wake-up time picker, so
    // the prompt lands in context (the next page is where they set the alarm).
    if (_currentPage == 10) {
      try {
        await AlarmChannel.requestAuthorization();
      } catch (e) {
        debugPrint('[OnboardingScreenV2] requestAuthorization failed: $e');
      }
      if (!mounted) return;
    }
    if (_currentPage == 11) {
      final alarm = _alarmTimeNotifier.value;
      cubit.setAlarmTime(alarm);
      // Default the bedtime to 8h of sleep before the wake-up alarm.
      _sleepTimeNotifier.value = _eightHoursBefore(alarm);
    } else if (_currentPage == 23) {
      cubit.setSleepTime(_sleepTimeNotifier.value);
    } else if (_currentPage == 27) {
      cubit.setScreenBlockStart(_blockStartNotifier.value);
    }
    // Block-apps step: run native Screen Time setup inline when opted in.
    if (_currentPage == 26 && state.wantsScreenBlock == true) {
      final stCubit = context.read<ScreenTimeCubit>();
      final granted = await stCubit.requestAuthorizationIfNeeded();
      if (!mounted) return;
      if (granted) {
        await stCubit.pickApps();
        if (!mounted) return;
      }
    }
    // Referral step: validate any entered code before advancing.
    if (_currentPage == 31) {
      final code = state.referralCode.trim();
      FocusScope.of(context).unfocus();
      if (code.isNotEmpty && state.referralStatus != ReferralStatus.valid) {
        await cubit.submitReferralCode();
        if (!mounted) return;
        if (cubit.state.referralStatus != ReferralStatus.valid) return;
      }
    }
    if (_currentPage == 35) {
      InAppReview.instance.requestReview();
    }
    _next();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // Bedtime that leaves 8h of sleep before [wake], wrapping past midnight.
  TimeOfDay _eightHoursBefore(TimeOfDay wake) {
    final min = (wake.hour * 60 + wake.minute - 8 * 60 + 24 * 60) % (24 * 60);
    return TimeOfDay(hour: min ~/ 60, minute: min % 60);
  }

  bool _canContinue(OnboardingState state) {
    switch (_currentPage) {
      case 1:
        return state.surveyAnswers.containsKey('morningPerson');
      case 2:
        return state.surveyAnswers.containsKey('ageRange');
      case 3:
        return state.surveyAnswers.containsKey('gender');
      case 4:
        return state.wakeChallenges.isNotEmpty;
      case 5:
        return state.surveyAnswers.containsKey('feelSettingAlarm');
      case 7:
        return state.desiredFeelings.isNotEmpty;
      case 12:
        return state.firstRoom != null;
      case 18:
        return state.sleepTiredDay != null;
      case 19:
        return state.sleepChallenges.isNotEmpty;
      case 22:
        return state.wantsSleepAlarm != null;
      case 26:
        return state.wantsScreenBlock != null;
      case 31:
        return state.referralStatus != ReferralStatus.checking &&
            state.referralStatus != ReferralStatus.invalid &&
            state.referralStatus != ReferralStatus.exhausted;
      default:
        return true;
    }
  }

  // Pages that handle their own navigation (no shared Continue button).
  bool _hasOwnNavigation(int page) =>
      page == 0 ||
      page == 28 || // notification
      page == 29 || // loading
      page == 32 || // sign in
      page == 36 || // signature
      page == 37 || // paywall
      page == 38; // trial reminder

  // ---- Editable plan-recap pickers (modal sheets) ----

  Future<void> _showSheet(Widget child) {
    final c = AppColors.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: c.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      // useSafeArea already places the sheet below the status bar, so only pad
      // the bottom here to avoid a doubled gap at the top.
      builder: (_) => SizedBox(
        height: 1.sh,
        child: SafeArea(top: false, child: child),
      ),
    );
  }

  void _editMission(OnboardingCubit cubit) {
    _showSheet(BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (_, s) => MissionPickerStep(
        selectedMission: s.selectedMission,
        selectedConfig: s.missionConfig,
        onSelected: (config) {
          cubit.setMission(config);
          Navigator.pop(context);
        },
      ),
    ));
  }

  // "Other" on the first-room step: nudge toward picking a place, but let the
  // user open the mission picker instead via the secondary button.
  Future<void> _promptFirstRoomOther(OnboardingCubit cubit) async {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final chooseOther = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/siren.png', height: 64.h),
            SizedBox(height: 24.h),
            Text(
              l10n.onboardingV2MissionPickerHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, height: 1.4),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.card,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    l10n.onboardingV2KeepChoosePlace,
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.onboardingV2ChooseOtherMission),
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (chooseOther == true) {
      cubit.setFirstRoom('other');
      _editMission(cubit);
    }
  }

  void _editSound(OnboardingCubit cubit) {
    _showSheet(BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (_, s) => SoundPickerStep(
        selectedId: s.soundId,
        onSelected: (id, name) {
          cubit.setSound(id, name);
          Navigator.pop(context);
        },
      ),
    ));
  }

  void _editDays(OnboardingCubit cubit) {
    _showSheet(BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (_, s) => DayPickerStep(
        repeatDays: s.repeatDays,
        onToggle: cubit.toggleDay,
      ),
    ));
  }

  void _editTime(OnboardingCubit cubit,
      {required TimeOfDay initial,
      required ValueChanged<TimeOfDay> onDone,
      required String title}) {
    final notifier = ValueNotifier(initial);
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    _showSheet(Column(
      children: [
        Expanded(child: TimePickerStep(title: title, notifier: notifier)),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: withHaptic(() {
                onDone(notifier.value);
                Navigator.pop(context);
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(l10n.onboardingContinue,
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    )).whenComplete(notifier.dispose);
  }

  Future<void> _editRoutine(OnboardingCubit cubit,
      {required RoutineMode mode,
      required List<String> current,
      required ValueChanged<List<String>> onDone}) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoutinePickerScreen(preselected: current, mode: mode),
      ),
    );
    if (result != null) onDone(result);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
      final cubit = context.read<OnboardingCubit>();
      final c = AppColors.of(context);
      final l10n = AppLocalizations.of(context);

      return Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header: a centered progress bar that keeps the same
                  // position whether or not the back button is shown (equal
                  // side zones), with the language selector pinned to the right
                  // on every page.
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                    child: Row(
                      children: [
                        // Left zone mirrors the right zone to keep the bar
                        // centered; holds the back button when available.
                        SizedBox(
                          width: 52.w,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: (_currentPage > 0 &&
                                    _currentPage != 29 &&
                                    _currentPage != 30 &&
                                    _currentPage != 37 &&
                                    _currentPage != 38)
                                ? GestureDetector(
                                    onTap: withHaptic(_back),
                                    child: Container(
                                      width: 50.w,
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: c.card,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.chevron_left_rounded,
                                          size: 30.sp, color: c.textPrimary),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 24.w),
                        // Progress bar — hidden (but space kept) on welcome
                        // and the last page so its position never shifts.
                        Expanded(
                          child: Opacity(
                            opacity: (_currentPage > 0 && !_isLastPage(state))
                                ? 1.0
                                : 0.0,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: LinearProgressIndicator(
                                value: _progressFraction(state),
                                backgroundColor: c.separator,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.orange),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24.w),
                        // Right zone: language selector, always available.
                        SizedBox(
                          width: 52.w,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: LanguageFlagButton(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _pages(state, cubit, l10n, c),
                    ),
                  ),

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
                                _currentPage == 11
                                    ? l10n.onboardingSetAlarmFor(
                                        _formatTime(alarmTime))
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
            if (_finalizing) const Positioned.fill(child: LoadingBarrier()),
          ],
        ),
      );
    });
  }

  // The ordered PageView children (pages 1..38; welcome is outside the view).
  List<Widget> _pages(OnboardingState state, OnboardingCubit cubit,
      AppLocalizations l10n, AppColors c) {
    final missionName = localizedMissionName(l10n, state.selectedMission);
    return [
      // 1-3: identity surveys
      SurveyStep(
        question: l10n.onboardingMorningPerson,
        options: [l10n.onboardingYes, l10n.onboardingNotYet],
        selectedOption: state.surveyAnswers['morningPerson'],
        onSelected: (v) => cubit.answerSurvey('morningPerson', v),
      ),
      SurveyStep(
        question: l10n.onboardingAgeRange,
        options: const ['13-17', '18-24', '25-34', '35-44', '45-54', '55+'],
        selectedOption: state.surveyAnswers['ageRange'],
        onSelected: (v) => cubit.answerSurvey('ageRange', v),
      ),
      SurveyStep(
        question: l10n.onboardingDescribesYou,
        options: [
          l10n.onboardingMale,
          l10n.onboardingFemale,
          l10n.onboardingOther,
        ],
        selectedOption: state.surveyAnswers['gender'],
        onSelected: (v) => cubit.answerSurvey('gender', v),
      ),
      // 4: wake-up challenges (multi-select)
      MultiSelectStep(
        question: l10n.onboardingV2WakeChallengesTitle,
        subtitle: l10n.onboardingV2MultiSelectHint,
        selected: state.wakeChallenges,
        onToggle: cubit.toggleWakeChallenge,
        options: [
          MultiSelectOption(
              value: 'sleepThrough',
              emoji: '😴',
              label: l10n.onboardingV2WakeChallengeSleepThrough),
          MultiSelectOption(
              value: 'snoozeLoop',
              emoji: '🔁',
              label: l10n.onboardingV2WakeChallengeSnooze),
          MultiSelectOption(
              value: 'stayInBed',
              emoji: '🛏️',
              label: l10n.onboardingV2WakeChallengeStayInBed),
          MultiSelectOption(
              value: 'scroll',
              emoji: '📱',
              label: l10n.onboardingV2WakeChallengeScroll),
          MultiSelectOption(
              value: 'fallAsleep',
              emoji: '💤',
              label: l10n.onboardingV2WakeChallengeFallAsleep),
          MultiSelectOption(
              value: 'tired',
              emoji: '🥱',
              label: l10n.onboardingV2WakeChallengeTired),
          MultiSelectOption(
              value: 'mindFog',
              emoji: '🌫️',
              label: l10n.onboardingV2WakeChallengeMindFog),
          MultiSelectOption(
              value: 'anxiety',
              emoji: '😰',
              label: l10n.onboardingV2WakeChallengeAnxiety),
        ],
      ),
      // 5: feeling when setting the alarm at night
      SurveyStep(
        question: l10n.onboardingFeelSettingAlarm,
        options: [
          l10n.onboardingMotivated,
          l10n.onboardingAnxiousSleep,
          l10n.onboardingDefeated,
          l10n.onboardingNeutral,
        ],
        selectedOption: state.surveyAnswers['feelSettingAlarm'],
        onSelected: (v) => cubit.answerSurvey('feelSettingAlarm', v),
      ),
      // 6: EDU — sleep inertia / biology ("It's not your fault")
      InfoStep(
        title: l10n.onboardingBiologyTitle,
        subtitle: l10n.onboardingBiologySubtitle,
        imagePlaceholder: Image.asset(
          'assets/onboarding/mental-health.png',
          height: 120.h,
          fit: BoxFit.contain,
        ),
        bodyText: l10n.onboardingBiologyBody,
        references: l10n.onboardingBiologyReferences,
      ),
      // 7: how would you like to feel (multi-select)
      MultiSelectStep(
        question: l10n.onboardingV2DesiredFeelingsTitle,
        subtitle: l10n.onboardingV2MultiSelectHint,
        selected: state.desiredFeelings,
        onToggle: cubit.toggleDesiredFeeling,
        options: [
          MultiSelectOption(
              value: 'wakeStraight',
              emoji: '⚡',
              label: l10n.onboardingV2FeelWakeStraight),
          MultiSelectOption(
              value: 'energy',
              emoji: '🔋',
              label: l10n.onboardingV2FeelEnergy),
          MultiSelectOption(
              value: 'good',
              emoji: '😊',
              label: l10n.onboardingV2FeelGood),
          MultiSelectOption(
              value: 'confident',
              emoji: '💪',
              label: l10n.onboardingV2FeelConfident),
          MultiSelectOption(
              value: 'winDay',
              emoji: '🏆',
              label: l10n.onboardingV2FeelWinDay),
        ],
      ),
      // 8: EDU — Levio gets you out of bed
      InfoStep(
        title: l10n.onboardingGetsYouOut,
        imagePlaceholder: Image.asset(
          'assets/icon.png',
          height: 120.h,
          fit: BoxFit.contain,
        ),
        chartPlaceholder: const EnergyChart(),
        bodyText: l10n.onboardingAvoidGroggy,
      ),
      // 9: EDU PROOF — built with scientists
      InfoStep(
        title: l10n.onboardingV2ProofScientistsTitle,
        subtitle: l10n.onboardingV2ProofScientistsSubtitle,
        imagePlaceholder: Text('🔬', style: TextStyle(fontSize: 80.sp)),
        bodyText: l10n.onboardingV2ProofScientistsBody,
      ),
      // 10: EDU — one alarm, one mission
      InfoStep(
        title: l10n.onboardingOneAlarmOneMission,
        chartPlaceholder: const TimelineComparison(),
      ),
      // 11: wake-up time
      TimePickerStep(
        title: l10n.onboardingTimePickerTitle,
        subtitleBuilder: (t) =>
            l10n.onboardingTimePickerSubtitle(_formatTime(t)),
        notifier: _alarmTimeNotifier,
      ),
      // 12: first room → mission
      FirstRoomStep(
        title: l10n.onboardingV2FirstRoomTitle,
        subtitle: l10n.onboardingV2FirstRoomSubtitle,
        selectedRoom: state.firstRoom,
        otherMissionLabel: missionName,
        onRoomSelected: cubit.setFirstRoom,
        onPickOther: () => _promptFirstRoomOther(cubit),
        kitchenLabel: l10n.onboardingV2RoomKitchen,
        bathroomLabel: l10n.onboardingV2RoomBathroom,
        outsideLabel: l10n.onboardingV2RoomOutside,
        otherLabel: l10n.onboardingV2RoomOther,
      ),
      // 13: EDU — mission explanation
      Builder(builder: (context) {
        final mission = state.selectedMission;
        final info = missionInfoFor(mission);
        final explanations = getMissionExplanations(l10n);
        final explanation =
            explanations[mission] ?? explanations[MissionType.pushUps]!;
        return InfoStep(
          title: explanation['title']!,
          imagePlaceholder: Container(
            width: 120.w,
            height: 120.h,
            decoration:
                BoxDecoration(color: info.iconBg, shape: BoxShape.circle),
            child: Center(child: MissionIcon(info: info, size: 70.sp)),
          ),
          subtitle: explanation['subtitle'],
          bodyText: explanation['body'],
        );
      }),
      // 14: wake-up routine (wake mode) — locked step preview + modify button.
      RelaxingActivitiesStep(
        title: l10n.onboardingV2WakeRoutineTitle,
        subtitle: l10n.onboardingV2WakeRoutineSubtitle,
        selected: state.wakeRoutine,
        onChanged: cubit.setWakeRoutine,
        mode: RoutineMode.wake,
        leadingIcon: Icons.wb_sunny_outlined,
      ),
      // 15: days
      DayPickerStep(repeatDays: state.repeatDays, onToggle: cubit.toggleDay),
      // 16: sound
      SoundPickerStep(selectedId: state.soundId, onSelected: cubit.setSound),
      // 17: CITATION — win the morning
      InfoStep(
        title: '',
        imagePlaceholder: Column(
          children: [
            Text('66',
                style: TextStyle(
                    fontSize: 48.sp,
                    color: c.separator,
                    fontFamily: 'Georgia')),
            SizedBox(height: 16.h),
            Text(
              l10n.onboardingQuoteWinMorning,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  height: 1.3),
            ),
            SizedBox(height: 16.h),
            Text(l10n.onboardingQuoteWinMorningAuthor,
                style: TextStyle(fontSize: 17.sp, color: c.textSecondary)),
          ],
        ),
      ),
      // 18: sleep — tired during the day?
      Builder(builder: (context) {
        final v = state.sleepTiredDay;
        return SurveyStep(
          question: l10n.onboardingV2SleepTiredTitle,
          options: [
            l10n.onboardingV2SleepTiredOften,
            l10n.onboardingV2SleepTiredSometimes,
            l10n.onboardingV2SleepTiredRarely,
          ],
          selectedOption: v,
          onSelected: cubit.setSleepTiredDay,
        );
      }),
      // 19: sleep challenges (multi-select)
      MultiSelectStep(
        question: l10n.onboardingV2SleepChallengesTitle,
        subtitle: l10n.onboardingV2MultiSelectHint,
        selected: state.sleepChallenges,
        onToggle: cubit.toggleSleepChallenge,
        options: [
          MultiSelectOption(
              value: 'hardToFall',
              emoji: '😣',
              label: l10n.onboardingV2SleepChallengeHardToFall),
          MultiSelectOption(
              value: 'wakeAtNight',
              emoji: '🌙',
              label: l10n.onboardingV2SleepChallengeWakeAtNight),
          MultiSelectOption(
              value: 'lateBed',
              emoji: '⏰',
              label: l10n.onboardingV2SleepChallengeLateBed),
          MultiSelectOption(
              value: 'racingMind',
              emoji: '🧠',
              label: l10n.onboardingV2SleepChallengeRacingMind),
          MultiSelectOption(
              value: 'notEnough',
              emoji: '⏳',
              label: l10n.onboardingV2SleepChallengeNotEnough),
          MultiSelectOption(
              value: 'groggy',
              emoji: '📱',
              label: l10n.onboardingV2SleepChallengeGroggy),
        ],
      ),
      // 20: EDU PB — sleep quality is the #1 predictor
      InfoStep(
        title: l10n.onboardingV2SleepQualityTitle,
        subtitle: l10n.onboardingV2SleepQualitySubtitle,
        imagePlaceholder: Text('🌙', style: TextStyle(fontSize: 80.sp)),
        bodyText: l10n.onboardingV2SleepQualityBody,
        references: l10n.onboardingV2SleepQualityReferences,
      ),
      // 21: EDU SOLUTION — Levio builds your sleep routine
      InfoStep(
        title: l10n.onboardingV2SleepSolutionTitle,
        subtitle: l10n.onboardingV2SleepSolutionSubtitle,
        imagePlaceholder: Text('🛌', style: TextStyle(fontSize: 80.sp)),
        bodyText: l10n.onboardingV2SleepSolutionBody,
      ),
      // 22: consistency → want a bedtime alarm?
      Builder(builder: (context) {
        final yes = l10n.onboardingYes;
        final no = l10n.onboardingNo;
        final v = state.wantsSleepAlarm;
        return SurveyStep(
          question: l10n.onboardingV2ConsistencyTitle,
          subtitle: l10n.onboardingV2ConsistencySubtitle,
          options: [yes, no],
          selectedOption: v == null ? null : (v ? yes : no),
          onSelected: (sel) => cubit.setWantsSleepAlarm(sel == yes),
        );
      }),
      // 23: bedtime picker (conditional) — shows sleep length vs the wake alarm.
      // Keyed to the alarm so the wheel re-seeds to 8h of sleep if the alarm
      // changes (the default value is set when the alarm is committed).
      TimePickerStep(
        key: ValueKey(
            'sleep-${state.alarmTime.hour}-${state.alarmTime.minute}'),
        title: l10n.onboardingSleepTimeTitle,
        subtitle: l10n.onboardingSleepTimeSubtitle,
        notifier: _sleepTimeNotifier,
        compareWakeTime: state.alarmTime,
      ),
      // 24: wind-down routine (night mode, conditional)
      RelaxingActivitiesStep(
        title: l10n.onboardingRelaxActivitiesTitle,
        subtitle: l10n.onboardingRelaxActivitiesSubtitle,
        selected: state.relaxingActivities,
        onChanged: cubit.setRelaxingActivities,
        mode: RoutineMode.night,
      ),
      // 25: EDU PB — screens kill sleep
      InfoStep(
        title: l10n.onboardingScreenEduTitle,
        imagePlaceholder: Text('📵', style: TextStyle(fontSize: 80.sp)),
        bodyText: l10n.onboardingScreenEduBody,
      ),
      // 26: block apps?
      Builder(builder: (context) {
        final yes = l10n.onboardingYes;
        final no = l10n.onboardingNo;
        final v = state.wantsScreenBlock;
        return SurveyStep(
          question: l10n.onboardingBlockApps,
          subtitle: l10n.onboardingBlockStartSubtitle,
          options: [yes, no],
          selectedOption: v == null ? null : (v ? yes : no),
          onSelected: (sel) => cubit.setWantsScreenBlock(sel == yes),
        );
      }),
      // 27: block-start picker (only when blocking without a bedtime to
      // derive the start time from)
      TimePickerStep(
        title: l10n.onboardingBlockStartTitle,
        subtitle: l10n.onboardingBlockStartSubtitle,
        notifier: _blockStartNotifier,
      ),
      // 28: notification permission
      NotificationStep(onNext: _next),
      // 29: loading
      LoadingStep(
        onComplete: () {
          if (!mounted) return;
          // Reveal the plan recap, then ask for ad-tracking (ATT) so the
          // prompt lands over the revealed plan.
          _next();
          BranchService.requestTrackingAuthorization();
        },
        steps: [
          l10n.onboardingV2LoadingStep1,
          l10n.onboardingV2LoadingStep2,
          l10n.onboardingV2LoadingStep3,
          if (state.wantsSleepAlarm == true) l10n.onboardingV2LoadingStep4,
          l10n.onboardingV2LoadingStep5,
          l10n.onboardingV2LoadingStep6,
        ],
      ),
      // 30: editable plan recap
      MorningPlanStep(
        alarmTime: state.alarmTime,
        mission: state.selectedMission,
        soundId: state.soundId,
        repeatDays: state.repeatDays,
        hasSleep: state.wantsSleepAlarm == true,
        sleepTime: state.sleepTime,
        relaxingActivities: state.relaxingActivities,
        blockApps: state.wantsScreenBlock == true,
        onEditTime: () => _editTime(cubit,
            initial: state.alarmTime,
            onDone: cubit.setAlarmTime,
            title: l10n.onboardingTimePickerTitle),
        onEditMission: () => _editMission(cubit),
        onEditSound: () => _editSound(cubit),
        onEditDays: () => _editDays(cubit),
        onEditSleepTime: state.wantsSleepAlarm == true
            ? () => _editTime(cubit,
                initial: state.sleepTime,
                onDone: cubit.setSleepTime,
                title: l10n.onboardingSleepTimeTitle)
            : null,
        onEditWakeRoutine: () => _editRoutine(cubit,
            mode: RoutineMode.wake,
            current: state.wakeRoutine,
            onDone: cubit.setWakeRoutine),
        onEditNightRoutine: state.wantsSleepAlarm == true
            ? () => _editRoutine(cubit,
                mode: RoutineMode.night,
                current: state.relaxingActivities,
                onDone: cubit.setRelaxingActivities)
            : null,
      ),
      // 31: referral
      ReferralStep(
        code: state.referralCode,
        status: state.referralStatus,
        onCodeChanged: cubit.setReferralCode,
      ),
      // 32: sign in
      SignInStep(
        title: l10n.onboardingSignInCreateTitle,
        subtitle: l10n.onboardingSignInCreateSubtitle,
        onSkip: _finalizeSignInStep,
        onSignInComplete: _finalizeSignInStep,
      ),
      // 33: RECALL — 5x faster
      InfoStep(
        title: l10n.onboarding5xFaster,
        chartPlaceholder: const SpeedometerChart(),
      ),
      // 34: RECALL PROOF — adopted by 200k
      InfoStep(
        title: l10n.onboardingV2Recall200kTitle,
        subtitle: l10n.onboardingAppOfTheYear,
        imagePlaceholder: Text('🌍', style: TextStyle(fontSize: 80.sp)),
        bodyText: l10n.onboardingV2Recall200kBody,
      ),
      // 35: RECALL PROOF — comments
      const RatingStep(),
      // 36: commitment
      SignatureStep(
        alarmTimeText: _formatTime(state.alarmTime),
        hasSleep: state.wantsSleepAlarm == true,
        onCommit: _next,
      ),
      // 37: paywall
      PaywallStep(onContinue: _next),
      // 38: trial reminder
      TrialReminderStep(onContinue: cubit.finishOnboarding),
    ];
  }
}
