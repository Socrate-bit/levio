import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/auth_service.dart';
import '../../subscription/services/analytics_service.dart';
import '../../subscription/services/referral_service.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  /// Marks the onboarding flow as in progress. Called when the user commits
  /// to the build-plan flow (e.g. on the welcome screen). AuthWrapper uses
  /// this to keep showing OnboardingScreen across reactive auth changes.
  void startOnboarding() {
    if (state.isInProgress) return;
    emit(state.copyWith(isInProgress: true));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'start'},
    );
  }

  /// Marks the onboarding flow as finished. Called at the end of the trial
  /// reminder step. AuthWrapper then routes to AppGateWrapper.
  void finishOnboarding() {
    emit(state.copyWith(isInProgress: false, isComplete: true));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'finish'},
    );
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

  void setMission(MissionType mission) {
    emit(state.copyWith(selectedMission: mission));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'mission', 'mission': mission.name},
    );
    AnalyticsService.setUserProperty('mission', mission.name);
  }

  void setKeepAlarmDuringMission(bool value) {
    emit(state.copyWith(keepAlarmDuringMission: value));
    AnalyticsService.capture(
      AnalyticsService.onboardingStep,
      {'step_name': 'alarm_during_mission', 'keep_ringing': value},
    );
    AnalyticsService.setUserProperty('keep_alarm_during_mission', value);
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
  ) async {
    final alarmTime = state.alarmTime;
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final selectedMission = state.selectedMission;
    final entry = AppAlarmEntry(
      id: '',
      dateTime: scheduled,
      missions: [MissionConfig(type: selectedMission)],
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
    } catch (e, st) {
      debugPrint('[OnboardingCubit] alarm creation failed: $e');
      AnalyticsService.trackError('OnboardingCubit.completeOnboarding.addAlarm', e, st);
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
        await ReferralService.redeemCode(state.referralCode.trim());
      } catch (e, st) {
        debugPrint('[OnboardingCubit] referral redeem failed: $e');
        AnalyticsService.trackError('OnboardingCubit.completeOnboarding.redeemCode', e, st);
      }
    }
    await subscriptionCubit.refreshUserType();
  }
}
