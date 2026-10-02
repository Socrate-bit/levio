import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/services/branch_service.dart';
import '../../auth/auth_service.dart';
import '../../subscription/services/analytics_service.dart';
import '../../subscription/services/referral_service.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../screentime/cubit/screentime_cubit.dart';
import '../../screentime/models/screentime_schedule.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../onboarding_config.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState()) {
    _restoreInProgress();
  }

  // Persisted "onboarding started but not finished" flag. The account is
  // created on "Build my plan", so after a relaunch mid-onboarding the user is
  // already signed in; this flag sends them back to the onboarding instead of
  // into the app with no alarm.
  static const _inProgressKey = 'onboarding_in_progress';

  // Persisted "phone number still to collect" flag, set when the onboarding
  // finishes with the beta_phone flag on. The phone screen is shown right
  // after the paywall and stays pending until a number is saved.
  static const _phonePendingKey = 'phone_step_pending';

  // Guards against re-entrant completion: the sign-in step can fire its
  // finalize callback more than once (e.g. a double-tap on "Skip for Now"),
  // and a second concurrent run would create duplicate alarms.
  bool _isCompleting = false;

  /// Reads the persisted in-progress flag at launch, then marks the state as
  /// restored so AuthWrapper can route a signed-in user.
  Future<void> _restoreInProgress() async {
    var inProgress = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      inProgress = prefs.getBool(_inProgressKey) ?? false;
    } catch (e, st) {
      debugPrint('[OnboardingCubit] restore in-progress flag failed: $e');
      AnalyticsService.trackError('OnboardingCubit._restoreInProgress', e, st);
    }
    emit(state.copyWith(
      isInProgress: state.isInProgress || inProgress,
      isRestored: true,
    ));
  }

  Future<void> _persistInProgress(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_inProgressKey, value);
    } catch (e, st) {
      debugPrint('[OnboardingCubit] persist in-progress flag failed: $e');
      AnalyticsService.trackError('OnboardingCubit._persistInProgress', e, st);
    }
  }

  /// Marks the onboarding flow as in progress. Called when the user commits
  /// to the build-plan flow (e.g. on the welcome screen). AuthWrapper uses
  /// this to keep showing OnboardingScreen across reactive auth changes.
  void startOnboarding() {
    emit(state.copyWith(isInProgress: true));
    _persistInProgress(true);
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'start'},
    );
  }

  /// Leaves the onboarding without completing it — used when an existing
  /// account signs in from the start screen, so the relaunch flag can't force
  /// that account back into an onboarding that would replace its alarms.
  void abandonOnboarding() {
    emit(state.copyWith(isInProgress: false));
    _persistInProgress(false);
  }

  /// Marks the onboarding flow as finished. Called at the end of the trial
  /// reminder step. AuthWrapper then routes to AppGateWrapper.
  void finishOnboarding() {
    emit(state.copyWith(isInProgress: false, isComplete: true));
    _persistInProgress(false);
    if (betaPhoneEnabled.value) _setPhonePending(true);
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'finish'},
    );
    // Branch conversion: registration funnel completed.
    BranchService.trackCompleteRegistration();
  }

  // Formats a TimeOfDay as HH:mm for analytics properties.
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void answerSurvey(String key, String value) {
    emit(state.copyWith(
      surveyAnswers: {...state.surveyAnswers, key: value},
    ));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'survey_$key', 'value': value},
    );
    // Persist the answer on the user profile (e.g. ageRange, gender).
    AnalyticsService.setUserProperty(key, value);
  }

  void setUsualWakeTime(TimeOfDay time) {
    emit(state.copyWith(usualWakeTime: time));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'usual_wake_time'},
    );
    AnalyticsService.setUserProperty('usual_wake_time', _formatTime(time));
  }

  void setIdealWakeTime(TimeOfDay time) {
    emit(state.copyWith(idealWakeTime: time, alarmTime: time));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'ideal_wake_time'},
    );
    AnalyticsService.setUserProperty('ideal_wake_time', _formatTime(time));
  }

  void setAlarmTime(TimeOfDay time) {
    emit(state.copyWith(alarmTime: time));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'alarm_time'},
    );
    AnalyticsService.setUserProperty('alarm_time', _formatTime(time));
  }

  void setMission(MissionConfig config) {
    emit(state.copyWith(
      selectedMission: config.type,
      missionConfig: config,
    ));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'mission', 'mission': config.type.name},
    );
    AnalyticsService.setUserProperty('mission', config.type.name);
  }

  void setKeepAlarmDuringMission(bool value) {
    emit(state.copyWith(keepAlarmDuringMission: value));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'alarm_during_mission', 'keep_ringing': value},
    );
    AnalyticsService.setUserProperty('keep_alarm_during_mission', value);
  }

  // --- Sleep section setters ---

  void setWantsSleepAlarm(bool value) {
    emit(state.copyWith(wantsSleepAlarm: value));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'wants_sleep_alarm', 'value': value},
    );
    AnalyticsService.setUserProperty('wants_sleep_alarm', value);
  }

  void setSleepTime(TimeOfDay time) {
    emit(state.copyWith(sleepTime: time));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'sleep_time'},
    );
    AnalyticsService.setUserProperty('sleep_time', _formatTime(time));
  }

  void setWantsScreenBlock(bool value) {
    emit(state.copyWith(wantsScreenBlock: value));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'wants_screen_block', 'value': value},
    );
    AnalyticsService.setUserProperty('wants_screen_block', value);
  }

  void setScreenBlockStart(TimeOfDay time) {
    emit(state.copyWith(screenBlockStart: time));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'screen_block_start'},
    );
  }

  void setRelaxingActivities(List<String> activities) {
    emit(state.copyWith(relaxingActivities: activities));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'relaxing_activities', 'count': activities.length},
    );
  }

  // --- v2 funnel setters ---

  void _toggle(Set<String> current, String value, String stepName,
      String property, void Function(Set<String>) apply) {
    final next = Set<String>.from(current);
    next.contains(value) ? next.remove(value) : next.add(value);
    apply(next);
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'funnel': 'v2', 'step_name': stepName, 'count': next.length},
    );
    AnalyticsService.setUserProperty(property, next.join(','));
  }

  void toggleWakeChallenge(String value) => _toggle(
        state.wakeChallenges,
        value,
        'wake_challenges',
        'wake_challenges',
        (s) => emit(state.copyWith(wakeChallenges: s)),
      );

  void toggleDesiredFeeling(String value) => _toggle(
        state.desiredFeelings,
        value,
        'desired_feelings',
        'desired_feelings',
        (s) => emit(state.copyWith(desiredFeelings: s)),
      );

  void toggleSleepChallenge(String value) => _toggle(
        state.sleepChallenges,
        value,
        'sleep_challenges',
        'sleep_challenges',
        (s) => emit(state.copyWith(sleepChallenges: s)),
      );

  void setSleepTiredDay(String value) {
    emit(state.copyWith(sleepTiredDay: value));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'funnel': 'v2', 'step_name': 'sleep_tired_day', 'value': value},
    );
    AnalyticsService.setUserProperty('sleep_tired_day', value);
  }

  void setWakeRoutine(List<String> steps) {
    emit(state.copyWith(wakeRoutine: steps));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'funnel': 'v2', 'step_name': 'wake_routine', 'count': steps.length},
    );
  }

  /// Resolves a picked first-room into a concrete mission. `kitchen`/`bathroom`
  /// become single-item object hunts; `outside` is a sky photo; `other` leaves
  /// the mission to the full mission picker.
  void setFirstRoom(String room) {
    MissionType? mission;
    List<String>? items;
    switch (room) {
      case 'kitchen':
        mission = MissionType.objectHunt;
        items = const ['Fridge'];
        break;
      case 'bathroom':
        mission = MissionType.objectHunt;
        items = const ['Shower'];
        break;
      case 'outside':
        mission = MissionType.skyPhoto;
        break;
    }
    emit(state.copyWith(
      firstRoom: room,
      firstRoomItems: items,
      selectedMission: mission ?? state.selectedMission,
      // Persist the resolved mission as a config too; 'other' leaves the
      // existing config in place for the full mission picker to overwrite.
      missionConfig: mission == null
          ? null
          : MissionConfig(type: mission, selectedItems: items),
    ));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'funnel': 'v2', 'step_name': 'first_room', 'room': room},
    );
    AnalyticsService.setUserProperty('first_room', room);
  }

  void setSound(String id, String name) {
    emit(state.copyWith(soundId: id, soundName: name));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'sound', 'sound_id': id},
    );
    AnalyticsService.setUserProperty('sound_id', id);
  }

  void toggleDay(int index) {
    final days = List<bool>.from(state.repeatDays);
    days[index] = !days[index];
    emit(state.copyWith(repeatDays: days));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'toggle_day', 'day_index': index, 'enabled': days[index]},
    );
  }

  void setReferralCode(String code) {
    emit(state.copyWith(referralCode: code, referralStatus: ReferralStatus.none));
  }

  // --- Beta phone screen (gated by beta_phone flag, shown after the paywall) ---

  void setPhoneNumber(String value) {
    emit(state.copyWith(phoneNumber: value));
  }

  /// Whether the post-paywall phone screen still has to be shown.
  Future<bool> isPhoneStepPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_phonePendingKey) ?? false;
    } catch (e, st) {
      debugPrint('[OnboardingCubit] read phone pending flag failed: $e');
      AnalyticsService.trackError('OnboardingCubit.isPhoneStepPending', e, st);
      return false;
    }
  }

  Future<void> _setPhonePending(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_phonePendingKey, value);
    } catch (e, st) {
      debugPrint('[OnboardingCubit] persist phone pending flag failed: $e');
      AnalyticsService.trackError('OnboardingCubit._setPhonePending', e, st);
    }
  }

  /// Persists the collected phone number on the user doc and clears the
  /// pending flag. Returns false when the save failed (e.g. offline).
  Future<bool> savePhoneNumber() async {
    final uid = AuthService.uidOrNull;
    if (uid == null) return false;
    final phone = state.phoneNumber.trim();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'phone': phone}, SetOptions(merge: true));
      // Personal data: kept in Firestore only, never sent to Mixpanel.
      await _setPhonePending(false);
      return true;
    } catch (e, st) {
      debugPrint('[OnboardingCubit] phone save failed: $e');
      AnalyticsService.trackError('OnboardingCubit.savePhoneNumber', e, st);
      return false;
    }
  }

  /// Client-side validation only — redemption happens in completeOnboarding.
  Future<void> submitReferralCode() async {
    if (state.referralCode.trim().isEmpty) return;
    emit(state.copyWith(referralStatus: ReferralStatus.checking));
    try {
      final result =
          await ReferralService.validateCode(state.referralCode.trim());
      if (result == null) {
        emit(state.copyWith(referralStatus: ReferralStatus.invalid));
      } else if (result == 'exhausted') {
        emit(state.copyWith(referralStatus: ReferralStatus.exhausted));
      } else {
        emit(state.copyWith(referralStatus: ReferralStatus.valid));
      }
    } catch (e, st) {
      debugPrint('[OnboardingCubit] referral check failed: $e');
      AnalyticsService.trackError('OnboardingCubit.checkReferralCode', e, st);
      emit(state.copyWith(referralStatus: ReferralStatus.invalid));
    }
  }

  /// Saves the configured alarm, redeems any validated referral code, and
  /// refreshes the user's type. Does NOT flip [isInProgress]; call
  /// [finishOnboarding] after the post-signin steps (paywall, trial reminder).
  Future<void> completeOnboarding(
    AlarmCubit alarmCubit,
    SubscriptionCubit subscriptionCubit,
    SettingsCubit settingsCubit,
    ScreenTimeCubit screenTimeCubit,
  ) async {
    // Bail if a completion is already running, so a re-entrant call can't
    // create a second set of alarms.
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      await _completeOnboarding(
          alarmCubit, subscriptionCubit, settingsCubit, screenTimeCubit);
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _completeOnboarding(
    AlarmCubit alarmCubit,
    SubscriptionCubit subscriptionCubit,
    SettingsCubit settingsCubit,
    ScreenTimeCubit screenTimeCubit,
  ) async {
    final alarmTime = state.alarmTime;
    final now = DateTime.now();
    // Next future occurrence of a time-of-day.
    DateTime nextOccurrence(TimeOfDay t) {
      var dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
      return dt;
    }

    final selectedMission = state.selectedMission;
    final entry = AppAlarmEntry(
      id: '',
      dateTime: nextOccurrence(alarmTime),
      missions: [state.missionConfig ?? MissionConfig(type: selectedMission)],
      name: 'Levio',
      soundId: state.soundId,
      repeatDays: state.repeatDays,
      isEnabled: true,
      isOneTime: !state.repeatDays.any((d) => d),
    );

    try {
      // Delete any existing alarms first so re-running completeOnboarding
      // (e.g. skip then sign-in) doesn't create duplicate alarms.
      final existingIds = alarmCubit.state.alarms.map((a) => a.id).toList();
      for (final id in existingIds) {
        await alarmCubit.removeAlarm(id);
      }
      await alarmCubit.addAlarm(entry);

      // Optional bedtime alarm whose mission is the wind-down routine built
      // from the relaxing-activity chips.
      if (state.wantsSleepAlarm == true) {
        final steps = state.relaxingActivities.isNotEmpty
            ? state.relaxingActivities
            : routinePresetSteps;
        final sleepEntry = AppAlarmEntry(
          id: '',
          dateTime: nextOccurrence(state.sleepTime),
          missions: [
            // Guided breathing precedes the habit routine on the sleep alarm.
            const MissionConfig(type: MissionType.breathing),
            MissionConfig(type: MissionType.routine, selectedItems: steps),
          ],
          name: 'Levio',
          soundId: state.soundId,
          repeatDays: state.repeatDays,
          isEnabled: true,
          isOneTime: !state.repeatDays.any((d) => d),
          isSleep: true,
          // Bedtime reminder notification on by default, 30 min before bedtime.
          reminderEnabled: true,
          reminderMinutesBefore: 30,
        );
        await alarmCubit.addAlarm(sleepEntry);
      }
    } catch (e, st) {
      debugPrint('[OnboardingCubit] alarm creation failed: $e');
      AnalyticsService.trackError('OnboardingCubit.completeOnboarding.addAlarm', e, st);
    }

    // Optional screen-time block from bedtime (or a picked start) to wake-up.
    // Skip if a schedule already exists so re-running completeOnboarding
    // (e.g. skip then sign-in) doesn't append duplicate schedules.
    if (state.wantsScreenBlock == true &&
        screenTimeCubit.state.schedules.isEmpty) {
      try {
        final start =
            state.wantsSleepAlarm == true ? state.sleepTime : state.screenBlockStart;
        // Keep blocking 20 min past wake-up so the user can't immediately scroll.
        final endTotal = (alarmTime.hour * 60 + alarmTime.minute + 20) % (24 * 60);
        // create() supplies a fresh id; override the window + repeat days.
        final schedule = ScreenTimeSchedule.create().copyWith(
          repeatDays: state.repeatDays,
          startHour: start.hour,
          startMinute: start.minute,
          endHour: endTotal ~/ 60,
          endMinute: endTotal % 60,
        );
        await screenTimeCubit.setEnabled(true);
        await screenTimeCubit.addSchedule(schedule);
      } catch (e, st) {
        debugPrint('[OnboardingCubit] screen block creation failed: $e');
        AnalyticsService.trackError(
            'OnboardingCubit.completeOnboarding.screenBlock', e, st);
      }
    }

    final keepRinging = state.keepAlarmDuringMission ?? false;
    await settingsCubit.setKeepAlarmDuringMission(keepRinging);

    // Persist survey answers + onboarding metadata to Firestore.
    final uid = AuthService.uidOrNull;
    if (uid != null) {
      try {
        final data = <String, dynamic>{
          ...state.surveyAnswers,
          'alarmTime': '${alarmTime.hour}:${alarmTime.minute}',
          'mission': selectedMission.name,
          'soundId': state.soundId,
          'repeatDays': state.repeatDays,
          'keepAlarmDuringMission': keepRinging,
          'wantsSleepAlarm': state.wantsSleepAlarm ?? false,
          'sleepTime': '${state.sleepTime.hour}:${state.sleepTime.minute}',
          'wantsScreenBlock': state.wantsScreenBlock ?? false,
          'relaxingActivities': state.relaxingActivities,
          'onboardingComplete': true,
          'completedAt': FieldValue.serverTimestamp(),
        };
        if (state.referralCode.trim().isNotEmpty) {
          data['referralCode'] = state.referralCode.trim();
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meta')
            .doc('onboarding')
            .set(data);
      } catch (e, st) {
        debugPrint('[OnboardingCubit] survey save failed: $e');
        AnalyticsService.trackError('OnboardingCubit.completeOnboarding.surveySave', e, st);
      }
    }

    // Redeem referral code if validated, then refresh user type
    if (state.referralStatus == ReferralStatus.valid &&
        state.referralCode.trim().isNotEmpty) {
      try {
        final userType =
            await ReferralService.redeemCode(state.referralCode.trim());
        AnalyticsService.capture(
          AnalyticsService.referralRedeemSuccess,
          {'user_type': userType},
        );
        AnalyticsService.setUserProperty('user_type', userType);
      } catch (e, st) {
        debugPrint('[OnboardingCubit] referral redeem failed: $e');
        AnalyticsService.trackError('OnboardingCubit.completeOnboarding.redeemCode', e, st);
      }
    }
    await subscriptionCubit.refreshUserType();
  }

  /// v2-funnel variant of [completeOnboarding]. Differs in two ways:
  /// 1. The wake-up alarm stacks the first-room mission and, when present, the
  ///    morning routine as a second `routine` mission.
  /// 2. The Firestore onboarding doc records the extra v2 survey answers.
  /// Everything else (bedtime alarm, screen block, settings, referral) matches.
  Future<void> completeOnboardingV2(
    AlarmCubit alarmCubit,
    SubscriptionCubit subscriptionCubit,
    SettingsCubit settingsCubit,
    ScreenTimeCubit screenTimeCubit,
  ) async {
    // Bail if a completion is already running, so a re-entrant call can't
    // create a second set of alarms.
    if (_isCompleting) return;
    _isCompleting = true;
    try {
      await _completeOnboardingV2(
          alarmCubit, subscriptionCubit, settingsCubit, screenTimeCubit);
    } finally {
      _isCompleting = false;
    }
  }

  Future<void> _completeOnboardingV2(
    AlarmCubit alarmCubit,
    SubscriptionCubit subscriptionCubit,
    SettingsCubit settingsCubit,
    ScreenTimeCubit screenTimeCubit,
  ) async {
    final alarmTime = state.alarmTime;
    final now = DateTime.now();
    DateTime nextOccurrence(TimeOfDay t) {
      var dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1));
      return dt;
    }

    final selectedMission = state.selectedMission;
    final missions = <MissionConfig>[
      state.missionConfig ?? MissionConfig(type: selectedMission),
      // Morning routine runs right after the wake-up mission.
      if (state.wakeRoutine.isNotEmpty)
        MissionConfig(
            type: MissionType.routine, selectedItems: state.wakeRoutine),
    ];
    final entry = AppAlarmEntry(
      id: '',
      dateTime: nextOccurrence(alarmTime),
      missions: missions,
      name: 'Levio',
      soundId: state.soundId,
      repeatDays: state.repeatDays,
      isEnabled: true,
      isOneTime: !state.repeatDays.any((d) => d),
    );

    try {
      final existingIds = alarmCubit.state.alarms.map((a) => a.id).toList();
      for (final id in existingIds) {
        await alarmCubit.removeAlarm(id);
      }
      await alarmCubit.addAlarm(entry);

      if (state.wantsSleepAlarm == true) {
        final steps = state.relaxingActivities.isNotEmpty
            ? state.relaxingActivities
            : routineNightPresetSteps;
        final sleepEntry = AppAlarmEntry(
          id: '',
          dateTime: nextOccurrence(state.sleepTime),
          missions: [
            // Guided breathing precedes the habit routine on the sleep alarm.
            const MissionConfig(type: MissionType.breathing),
            MissionConfig(type: MissionType.routine, selectedItems: steps),
          ],
          name: 'Levio',
          soundId: state.soundId,
          repeatDays: state.repeatDays,
          isEnabled: true,
          isOneTime: !state.repeatDays.any((d) => d),
          isSleep: true,
          // Bedtime reminder notification on by default, 30 min before bedtime.
          reminderEnabled: true,
          reminderMinutesBefore: 30,
        );
        await alarmCubit.addAlarm(sleepEntry);
      }
    } catch (e, st) {
      debugPrint('[OnboardingCubit] v2 alarm creation failed: $e');
      AnalyticsService.trackError(
          'OnboardingCubit.completeOnboardingV2.addAlarm', e, st);
    }

    // Skip if a schedule already exists so re-running completeOnboardingV2
    // doesn't append duplicate screen-block schedules.
    if (state.wantsScreenBlock == true &&
        screenTimeCubit.state.schedules.isEmpty) {
      try {
        final start = state.wantsSleepAlarm == true
            ? state.sleepTime
            : state.screenBlockStart;
        final endTotal =
            (alarmTime.hour * 60 + alarmTime.minute + 20) % (24 * 60);
        final schedule = ScreenTimeSchedule.create().copyWith(
          repeatDays: state.repeatDays,
          startHour: start.hour,
          startMinute: start.minute,
          endHour: endTotal ~/ 60,
          endMinute: endTotal % 60,
        );
        await screenTimeCubit.setEnabled(true);
        await screenTimeCubit.addSchedule(schedule);
      } catch (e, st) {
        debugPrint('[OnboardingCubit] v2 screen block creation failed: $e');
        AnalyticsService.trackError(
            'OnboardingCubit.completeOnboardingV2.screenBlock', e, st);
      }
    }

    final keepRinging = state.keepAlarmDuringMission ?? false;
    await settingsCubit.setKeepAlarmDuringMission(keepRinging);

    final uid = AuthService.uidOrNull;
    if (uid != null) {
      try {
        final data = <String, dynamic>{
          ...state.surveyAnswers,
          'funnel': 'v2',
          'alarmTime': '${alarmTime.hour}:${alarmTime.minute}',
          'mission': selectedMission.name,
          'firstRoom': state.firstRoom,
          'wakeRoutine': state.wakeRoutine,
          'wakeChallenges': state.wakeChallenges.toList(),
          'desiredFeelings': state.desiredFeelings.toList(),
          'sleepChallenges': state.sleepChallenges.toList(),
          'sleepTiredDay': state.sleepTiredDay,
          'soundId': state.soundId,
          'repeatDays': state.repeatDays,
          'keepAlarmDuringMission': keepRinging,
          'wantsSleepAlarm': state.wantsSleepAlarm ?? false,
          'sleepTime': '${state.sleepTime.hour}:${state.sleepTime.minute}',
          'wantsScreenBlock': state.wantsScreenBlock ?? false,
          'relaxingActivities': state.relaxingActivities,
          'onboardingComplete': true,
          'completedAt': FieldValue.serverTimestamp(),
        };
        if (state.referralCode.trim().isNotEmpty) {
          data['referralCode'] = state.referralCode.trim();
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('meta')
            .doc('onboarding')
            .set(data);
      } catch (e, st) {
        debugPrint('[OnboardingCubit] v2 survey save failed: $e');
        AnalyticsService.trackError(
            'OnboardingCubit.completeOnboardingV2.surveySave', e, st);
      }
    }

    if (state.referralStatus == ReferralStatus.valid &&
        state.referralCode.trim().isNotEmpty) {
      try {
        final userType =
            await ReferralService.redeemCode(state.referralCode.trim());
        AnalyticsService.capture(
          AnalyticsService.referralRedeemSuccess,
          {'user_type': userType},
        );
        AnalyticsService.setUserProperty('user_type', userType);
      } catch (e, st) {
        debugPrint('[OnboardingCubit] v2 referral redeem failed: $e');
        AnalyticsService.trackError(
            'OnboardingCubit.completeOnboardingV2.redeemCode', e, st);
      }
    }
    await subscriptionCubit.refreshUserType();
  }
}
