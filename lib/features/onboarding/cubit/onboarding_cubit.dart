import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/auth_service.dart';
import '../../../services/referral_service.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  void answerSurvey(String key, String value) {
    emit(state.copyWith(
      surveyAnswers: {...state.surveyAnswers, key: value},
    ));
  }

  void setUsualWakeTime(TimeOfDay time) {
    emit(state.copyWith(usualWakeTime: time));
  }

  void setIdealWakeTime(TimeOfDay time) {
    emit(state.copyWith(idealWakeTime: time, alarmTime: time));
  }

  void setAlarmTime(TimeOfDay time) {
    emit(state.copyWith(alarmTime: time));
  }

  void setMission(MissionType mission) {
    emit(state.copyWith(selectedMission: mission));
  }

  void setSound(String id, String name) {
    emit(state.copyWith(soundId: id, soundName: name));
  }

  void toggleDay(int index) {
    final days = List<bool>.from(state.repeatDays);
    days[index] = !days[index];
    emit(state.copyWith(repeatDays: days));
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
    } catch (e) {
      debugPrint('[OnboardingCubit] referral check failed: $e');
      emit(state.copyWith(referralStatus: ReferralStatus.invalid));
    }
  }

  Future<void> completeOnboarding(
    AlarmCubit alarmCubit,
    AuthCubit authCubit,
  ) async {
    final alarmTime = state.alarmTime ?? state.targetTime;
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

    final selectedMission = state.selectedMission ?? MissionType.pushUps;
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
      await alarmCubit.addAlarm(entry);
    } catch (e) {
      debugPrint('[OnboardingCubit] alarm creation failed: $e');
    }

    // Save survey data + onboarding complete flag to Firestore (only if logged in)
    final uid = AuthService.uidOrNull;
    if (uid != null) {
      try {
        final keepRinging = state.surveyAnswers['alarmDuringMission'] ==
            'Keep alarm ringing while completing the mission.';
        final data = {
          ...state.surveyAnswers,
          'alarmTime': '${alarmTime.hour}:${alarmTime.minute}',
          'mission': (state.selectedMission ?? MissionType.pushUps).name,
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
      } catch (e) {
        debugPrint('[OnboardingCubit] survey save failed: $e');
      }
    }

    // Redeem referral code if validated, then refresh user type
    if (state.referralStatus == ReferralStatus.valid &&
        state.referralCode.trim().isNotEmpty) {
      try {
        await ReferralService.redeemCode(state.referralCode.trim());
      } catch (e) {
        debugPrint('[OnboardingCubit] referral redeem failed: $e');
      }
    }
    await authCubit.loadUserType();

    emit(state.copyWith(isComplete: true));
  }
}
