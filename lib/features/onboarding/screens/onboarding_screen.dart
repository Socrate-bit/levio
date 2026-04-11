import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/bottom_nav_shell.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../missions/models/mission.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/day_picker_step.dart';
import '../widgets/dna_helix.dart';
import '../widgets/energy_chart.dart';
import '../widgets/info_step.dart';
import '../widgets/loading_step.dart';
import '../widgets/mission_picker_step.dart';
import '../widgets/morning_plan_step.dart';
import '../widgets/notification_step.dart';
import '../widgets/rating_step.dart';
import '../widgets/referral_step.dart';
import '../widgets/sign_in_step.dart';
import '../widgets/signature_step.dart';
import '../widgets/sound_picker_step.dart';
import '../widgets/speedometer_chart.dart';
import '../widgets/timeline_comparison.dart';
import '../widgets/survey_step.dart';
import '../widgets/time_picker_step.dart';
import '../widgets/welcome_step.dart';

const _totalPages = 33;

// Mission explanation data
const _missionExplanations = <MissionType, Map<String, String>>{
  MissionType.pushUps: {
    'title': 'Why doing push ups wakes you up',
    'subtitle': 'Gets your blood pumping right away',
    'body':
        'Short bursts of effort spike cortisol and adrenaline, raising heart rate and body temperature so you feel awake fast.',
  },
  MissionType.squats: {
    'title': 'Why doing squats wakes you up',
    'subtitle': 'Activates your largest muscles',
    'body':
        'Squats engage your glutes and quads, driving blood flow to your brain and clearing morning fog in seconds.',
  },
  MissionType.shakePhone: {
    'title': 'Why shaking your phone wakes you up',
    'subtitle': 'Forces you to move',
    'body':
        'The physical act of shaking gets your arms moving and your brain engaged, making it impossible to drift back to sleep.',
  },
  MissionType.math: {
    'title': 'Why solving math wakes you up',
    'subtitle': 'Wakes up your brain',
    'body':
        'Solving problems forces your prefrontal cortex online, cutting through sleep inertia with pure cognitive effort.',
  },
  MissionType.skyPhoto: {
    'title': 'Why taking a sky photo wakes you up',
    'subtitle': 'Gets you to the window',
    'body':
        'Walking to see the sky exposes you to natural light, the most powerful signal to your circadian clock that it\'s time to wake.',
  },
  MissionType.makeBed: {
    'title': 'Why making your bed wakes you up',
    'subtitle': 'Starts your day with a win',
    'body':
        'Completing one small task creates momentum. A made bed means you\'ve already accomplished something before your day begins.',
  },
  MissionType.objectHunt: {
    'title': 'Why an object hunt wakes you up',
    'subtitle': 'Gets you out of bed',
    'body':
        'Searching for an object forces you to stand, walk, and engage your surroundings — the ultimate anti-snooze strategy.',
  },
  MissionType.petHunt: {
    'title': 'Why finding your pet wakes you up',
    'subtitle': 'Morning bonding time',
    'body':
        'Finding your pet gets you moving and starts your day with a moment of connection and joy.',
  },
  MissionType.natureHunt: {
    'title': 'Why a nature hunt wakes you up',
    'subtitle': 'Connects you to the outdoors',
    'body':
        'Stepping outside to photograph nature floods your senses with fresh air and light, resetting your internal clock.',
  },
  MissionType.touchGrass: {
    'title': 'Why touching grass wakes you up',
    'subtitle': 'Ground yourself in the morning',
    'body':
        'Going outside to touch grass exposes you to sunlight and fresh air, two of the strongest wake-up signals for your body.',
  },
  MissionType.bibleVerse: {
    'title': 'Why reading a verse wakes you up',
    'subtitle': 'Starts your day with purpose',
    'body':
        'Speaking a verse aloud engages your voice, mind, and spirit, anchoring your morning in meaning.',
  },
  MissionType.affirmation: {
    'title': 'Why affirmations wake you up',
    'subtitle': 'Sets your mindset for the day',
    'body':
        'Reading affirmations aloud activates your voice and focus, replacing grogginess with intention and clarity.',
  },
};

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

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  void _next() => _goToPage(_currentPage + 1);

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
      case 16: // time picker (always has default)
      case 17: // info
      case 18: // info
        return true;
      case 19:
        return state.selectedMission != null;
      case 20: // info
      case 21: // time picker
      case 22: // day picker
      case 23: // sound picker
        return true;
      case 24:
        return state.surveyAnswers.containsKey('alarmDuringMission');
      case 25:
        return state.surveyAnswers.containsKey('heardFrom');
      case 26: // referral (optional)
      case 27: // rating
      case 28: // sign in
      case 29: // notification — has own buttons
      case 30: // signature — has own button
      case 31: // loading — auto-advances
      case 32: // summary
        return true;
      default:
        return true;
    }
  }

  // Pages that handle their own navigation (no shared Continue button)
  bool _hasOwnNavigation(int page) =>
      page == 0 || page == 29 || page == 30 || page == 31;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          final c = AppColors.of(context);

          return Scaffold(
            backgroundColor: c.background,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Progress bar + back (hidden on welcome & loading)
                  if (_currentPage > 0 && _currentPage < _totalPages - 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          if (_currentPage > 0 && _currentPage != 31)
                            GestureDetector(
                              onTap: _back,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c.card,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chevron_left,
                                    size: 20, color: c.textPrimary),
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
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.orange),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Page content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 0: Welcome
                        WelcomeStep(
                          onBuildPlan: _next,
                          onSignIn: () => _goToPage(27),
                        ),
                        // 1-5: Survey questions
                        SurveyStep(
                          question: 'Do you feel like a morning person?',
                          options: const ['Yes', 'Not yet'],
                          selectedOption: state.surveyAnswers['morningPerson'],
                          onSelected: (v) =>
                              cubit.answerSurvey('morningPerson', v),
                        ),
                        SurveyStep(
                          question: "What's your age range?",
                          options: const [
                            '13-17',
                            '18-24',
                            '25-34',
                            '35-44',
                            '45-54',
                            '55+'
                          ],
                          selectedOption: state.surveyAnswers['ageRange'],
                          onSelected: (v) =>
                              cubit.answerSurvey('ageRange', v),
                        ),
                        SurveyStep(
                          question: 'What best describes you?',
                          options: const ['Male', 'Female', 'Other'],
                          selectedOption: state.surveyAnswers['gender'],
                          onSelected: (v) =>
                              cubit.answerSurvey('gender', v),
                        ),
                        SurveyStep(
                          question:
                              'What keeps you in bed after the alarm?',
                          options: const [
                            'Phone scrolling',
                            'Snooze loop',
                            'Sleep through alarms',
                            'I wake up but stay in bed',
                          ],
                          selectedOption: state.surveyAnswers['bedProblem'],
                          onSelected: (v) =>
                              cubit.answerSurvey('bedProblem', v),
                        ),
                        SurveyStep(
                          question:
                              'First thought when the alarm goes off?',
                          options: const [
                            "I'm up",
                            'Just 5 more minutes',
                            "I'll set another alarm",
                            'Why did I do this?',
                          ],
                          selectedOption:
                              state.surveyAnswers['firstThought'],
                          onSelected: (v) =>
                              cubit.answerSurvey('firstThought', v),
                        ),
                        // 6: Info - Energy levels
                        InfoStep(
                          title: 'Levio gets you out of bed',
                          imagePlaceholder: const EnergyChart(),
                          bodyText:
                              "Avoid the 'groggy zone'. Levio launches you straight into alertness.",
                        ),
                        // 7-9: More surveys
                        SurveyStep(
                          question: 'How many alarms do you set?',
                          options: const ['One', '2-3', '4+'],
                          selectedOption: state.surveyAnswers['alarmCount'],
                          onSelected: (v) =>
                              cubit.answerSurvey('alarmCount', v),
                        ),
                        SurveyStep(
                          question:
                              'If you set one alarm, would you wake up?',
                          options: const ['Yes', 'Sometimes', 'No'],
                          selectedOption:
                              state.surveyAnswers['oneAlarmWakeUp'],
                          onSelected: (v) =>
                              cubit.answerSurvey('oneAlarmWakeUp', v),
                        ),
                        SurveyStep(
                          question:
                              'Do you ever turn off the alarm and go back to sleep?',
                          options: const [
                            'Often',
                            'Sometimes',
                            'Rarely',
                            'Never'
                          ],
                          selectedOption:
                              state.surveyAnswers['turnOffSleep'],
                          onSelected: (v) =>
                              cubit.answerSurvey('turnOffSleep', v),
                        ),
                        // 10: Info - One alarm one mission
                        InfoStep(
                          title: 'One alarm. One mission.',
                          imagePlaceholder: const TimelineComparison(),
                        ),
                        // 11-13: More surveys
                        SurveyStep(
                          question:
                              'How do you feel setting your alarm at night?',
                          options: const [
                            'Motivated',
                            'Anxious about sleep',
                            'Defeated',
                            'Neutral',
                          ],
                          selectedOption:
                              state.surveyAnswers['feelSettingAlarm'],
                          onSelected: (v) =>
                              cubit.answerSurvey('feelSettingAlarm', v),
                        ),
                        SurveyStep(
                          question:
                              'How do you feel right after waking up?',
                          options: const [
                            'Ready to go',
                            'Groggy',
                            'Anxious or stressed',
                            'Neutral',
                          ],
                          selectedOption:
                              state.surveyAnswers['feelAfterWaking'],
                          onSelected: (v) =>
                              cubit.answerSurvey('feelAfterWaking', v),
                        ),
                        SurveyStep(
                          question:
                              'How long until you feel fully awake?',
                          options: const [
                            'Instantly',
                            '10-15 minutes',
                            '30 minutes or more',
                          ],
                          selectedOption:
                              state.surveyAnswers['timeToAwake'],
                          onSelected: (v) =>
                              cubit.answerSurvey('timeToAwake', v),
                        ),
                        // 14: Info - Biology not laziness
                        InfoStep(
                          title: 'Biology, Not Laziness',
                          centerTitle: true,
                          imagePlaceholder: const DnaHelix(),
                          bodyText:
                              "When the alarm rings, your prefrontal cortex is still asleep. This is 'Sleep Inertia.' You can't think your way out of bed when your brain is offline.",
                        ),
                        // 15: Info - Speedometer
                        InfoStep(
                          title:
                              'Get out of bed 5x faster with Levio vs on your own',
                          imagePlaceholder: const SpeedometerChart(),
                        ),
                        // 16: Time picker - usual wake time (was 15)
                        TimePickerStep(
                          title:
                              'What time do you usually get out of bed?',
                          subtitle:
                              'This helps us set a realistic first target.',
                          time: state.usualWakeTime,
                          onTimeChanged: cubit.setUsualWakeTime,
                        ),
                        // 17: Info - Target time
                        Builder(builder: (context) {
                          final target = state.targetTime;
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
                                const SizedBox(height: 16),
                                Text(
                                  '+45 minutes every morning',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.orange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+22 hours this month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // 18: Info - Quote
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
                        // 19: Mission picker
                        MissionPickerStep(
                          selectedMission: state.selectedMission,
                          onSelected: cubit.setMission,
                        ),
                        // 20: Info - Mission explanation
                        Builder(builder: (context) {
                          final mission =
                              state.selectedMission ?? MissionType.pushUps;
                          final explanation =
                              _missionExplanations[mission] ??
                                  _missionExplanations[MissionType.pushUps]!;
                          return InfoStep(
                            title: explanation['title']!,
                            imagePlaceholder: Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: c.separator,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Image placeholder',
                                  style:
                                      TextStyle(color: c.textSecondary),
                                ),
                              ),
                            ),
                            subtitle: explanation['subtitle'],
                            bodyText: explanation['body'],
                          );
                        }),
                        // 21: Alarm time picker
                        Builder(builder: (context) {
                          final alarmTime =
                              state.alarmTime ?? state.targetTime;
                          return TimePickerStep(
                            title: 'Set your first Levio time',
                            subtitle:
                                "We'll wake you at ${_formatTime(alarmTime)} with your mission.",
                            time: alarmTime,
                            onTimeChanged: cubit.setAlarmTime,
                          );
                        }),
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
                        SurveyStep(
                          question:
                              'Play your alarm during the mission?',
                          options: const [
                            'Keep alarm ringing while completing the mission.',
                            'Stop alarm ringing unless I leave the app during the mission.',
                          ],
                          selectedOption:
                              state.surveyAnswers['alarmDuringMission'],
                          onSelected: (v) =>
                              cubit.answerSurvey('alarmDuringMission', v),
                        ),
                        // 25: Where heard about us
                        SurveyStep(
                          question: 'Where did you hear about us?',
                          options: const [
                            'YouTube',
                            'Facebook',
                            'Twitter',
                            'Reddit',
                            'App Store',
                            'Friend or family',
                            'Other',
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
                          onSelected: (v) {
                              cubit.answerSurvey('heardFrom', v);
                              _next();
                          },
                        ),
                        // 26: Referral code
                        ReferralStep(
                          code: state.referralCode,
                          status: state.referralStatus,
                          onCodeChanged: cubit.setReferralCode,
                          onSubmit: cubit.submitReferralCode,
                        ),
                        // 27: Rating
                        const RatingStep(),
                        // 28: Sign in (placeholder)
                        SignInStep(onSkip: _next),
                        // 29: Notification permission
                        NotificationStep(onNext: _next),
                        // 30: Signature
                        SignatureStep(
                          alarmTimeText: _formatTime(
                              state.alarmTime ?? state.targetTime),
                          onCommit: _next,
                        ),
                        // 31: Loading
                        LoadingStep(
                          onComplete: () async {
                            final alarmCubit =
                                context.read<AlarmCubit>();
                            await cubit
                                .completeOnboarding(alarmCubit);
                            if (mounted) _next();
                          },
                        ),
                        // 32: Morning plan summary
                        MorningPlanStep(
                          alarmTime:
                              state.alarmTime ?? state.targetTime,
                          mission: state.selectedMission ??
                              MissionType.pushUps,
                          soundName: state.soundName,
                          repeatDays: state.repeatDays,
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
                                ? () {
                                    // Special: rating step triggers in_app_review
                                    if (_currentPage == 27) {
                                      InAppReview.instance.requestReview();
                                    }
                                    // Last page: go to app
                                    if (_currentPage == _totalPages - 1) {
                                      Navigator.of(context)
                                          .pushReplacement(
                                        PageRouteBuilder(
                                          pageBuilder: (_, _, _) =>
                                              const BottomNavShell(),
                                          transitionsBuilder:
                                              (_, animation, _, child) =>
                                                  FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                          transitionDuration:
                                              const Duration(
                                                  milliseconds: 400),
                                        ),
                                      );
                                      return;
                                    }
                                    _next();
                                  }
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
                              _currentPage == _totalPages - 1
                                  ? 'Continue'
                                  : _currentPage == 21
                                      ? 'Set alarm for ${_formatTime(state.alarmTime ?? state.targetTime)}'
                                      : 'Continue',
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
        },
      ),
    );
  }
}
