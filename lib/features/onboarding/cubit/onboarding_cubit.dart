import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../missions/models/mission.dart';
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
    // Auto-set alarm time to target (wake time - 30 min)
    final target = state.copyWith(usualWakeTime: time).targetTime;
    emit(state.copyWith(usualWakeTime: time, alarmTime: target));
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

  Future<void> submitReferralCode() async {
    if (state.referralCode.trim().isEmpty) return;
    emit(state.copyWith(referralStatus: ReferralStatus.checking));
    try {
      final doc = await FirebaseFirestore.instance
          .collection('referralCodes')
          .doc(state.referralCode.trim())
          .get();
      emit(state.copyWith(
        referralStatus: doc.exists ? ReferralStatus.valid : ReferralStatus.invalid,
      ));
    } catch (e) {
      debugPrint('[OnboardingCubit] referral check failed: $e');
      emit(state.copyWith(referralStatus: ReferralStatus.invalid));
    }
  }

  Future<void> completeOnboarding(AlarmCubit alarmCubit) async {
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

    final entry = AppAlarmEntry(
      id: '',
      dateTime: scheduled,
      missionType: state.selectedMission ?? MissionType.pushUps,
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

    // Store preferences
    final prefs = await SharedPreferences.getInstance();
    final keepRinging = state.surveyAnswers['alarmDuringMission'] ==
        'Keep alarm ringing while completing the mission.';
    await prefs.setBool('keep_alarm_during_mission', keepRinging);

    // Save survey data to Firestore
    try {
      final data = {
        ...state.surveyAnswers,
        'alarmTime': '${alarmTime.hour}:${alarmTime.minute}',
        'mission': (state.selectedMission ?? MissionType.pushUps).name,
        'soundId': state.soundId,
        'repeatDays': state.repeatDays,
        'completedAt': FieldValue.serverTimestamp(),
      };
      if (state.referralCode.trim().isNotEmpty) {
        data['referralCode'] = state.referralCode.trim();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.uid)
          .collection('meta')
          .doc('onboarding')
          .set(data);
    } catch (e) {
      debugPrint('[OnboardingCubit] survey save failed: $e');
    }

    // Mark onboarding complete
    await prefs.setBool('onboarding_complete', true);
    emit(state.copyWith(isComplete: true));
  }
}
