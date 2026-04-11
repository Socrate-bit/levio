import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../missions/models/mission.dart';

enum ReferralStatus { none, checking, valid, invalid }

class OnboardingState extends Equatable {
  final int currentPage;
  final Map<String, String> surveyAnswers;
  final TimeOfDay usualWakeTime;
  final TimeOfDay? alarmTime;
  final MissionType? selectedMission;
  final String soundId;
  final String soundName;
  final List<bool> repeatDays;
  final String referralCode;
  final ReferralStatus referralStatus;
  final bool isComplete;

  const OnboardingState({
    this.currentPage = 0,
    this.surveyAnswers = const {},
    this.usualWakeTime = const TimeOfDay(hour: 7, minute: 30),
    this.alarmTime,
    this.selectedMission,
    this.soundId = 'default',
    this.soundName = 'Default',
    this.repeatDays = const [false, true, true, true, true, true, false],
    this.referralCode = '',
    this.referralStatus = ReferralStatus.none,
    this.isComplete = false,
  });

  TimeOfDay get targetTime {
    final totalMinutes = usualWakeTime.hour * 60 + usualWakeTime.minute - 30;
    final adjusted = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;
    return TimeOfDay(hour: adjusted ~/ 60, minute: adjusted % 60);
  }

  OnboardingState copyWith({
    int? currentPage,
    Map<String, String>? surveyAnswers,
    TimeOfDay? usualWakeTime,
    TimeOfDay? alarmTime,
    MissionType? selectedMission,
    String? soundId,
    String? soundName,
    List<bool>? repeatDays,
    String? referralCode,
    ReferralStatus? referralStatus,
    bool? isComplete,
  }) =>
      OnboardingState(
        currentPage: currentPage ?? this.currentPage,
        surveyAnswers: surveyAnswers ?? this.surveyAnswers,
        usualWakeTime: usualWakeTime ?? this.usualWakeTime,
        alarmTime: alarmTime ?? this.alarmTime,
        selectedMission: selectedMission ?? this.selectedMission,
        soundId: soundId ?? this.soundId,
        soundName: soundName ?? this.soundName,
        repeatDays: repeatDays ?? this.repeatDays,
        referralCode: referralCode ?? this.referralCode,
        referralStatus: referralStatus ?? this.referralStatus,
        isComplete: isComplete ?? this.isComplete,
      );

  @override
  List<Object?> get props => [
        currentPage,
        surveyAnswers,
        usualWakeTime,
        alarmTime,
        selectedMission,
        soundId,
        soundName,
        repeatDays,
        referralCode,
        referralStatus,
        isComplete,
      ];
}
