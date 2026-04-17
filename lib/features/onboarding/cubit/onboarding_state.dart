import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../missions/models/mission.dart';

enum ReferralStatus { none, checking, valid, invalid, exhausted }

class OnboardingState extends Equatable {
  final int currentPage;
  final Map<String, String> surveyAnswers;
  final TimeOfDay usualWakeTime;
  final TimeOfDay idealWakeTime;
  final TimeOfDay alarmTime;
  final MissionType selectedMission;
  final String soundId;
  final String soundName;
  final List<bool> repeatDays;
  final String referralCode;
  final ReferralStatus referralStatus;
  final bool isInProgress;
  final bool isComplete;

  const OnboardingState({
    this.currentPage = 0,
    this.surveyAnswers = const {},
    this.usualWakeTime = const TimeOfDay(hour: 7, minute: 30),
    this.idealWakeTime = const TimeOfDay(hour: 7, minute: 0),
    this.alarmTime = const TimeOfDay(hour: 7, minute: 0),
    this.selectedMission = MissionType.pushUps,
    this.soundId = 'default',
    this.soundName = 'Default',
    this.repeatDays = const [false, true, true, true, true, true, false],
    this.referralCode = '',
    this.referralStatus = ReferralStatus.none,
    this.isInProgress = false,
    this.isComplete = false,
  });

  /// Minutes gained by waking at ideal vs usual time. Returns 0 when
  /// the ideal time is the same or later than the usual time.
  int get wakeTimeDeltaMinutes {
    final usualMin = usualWakeTime.hour * 60 + usualWakeTime.minute;
    final idealMin = idealWakeTime.hour * 60 + idealWakeTime.minute;
    final delta = usualMin - idealMin;
    return delta > 0 ? delta : 0;
  }

  TimeOfDay get targetTime => idealWakeTime;

  OnboardingState copyWith({
    int? currentPage,
    Map<String, String>? surveyAnswers,
    TimeOfDay? usualWakeTime,
    TimeOfDay? idealWakeTime,
    TimeOfDay? alarmTime,
    MissionType? selectedMission,
    String? soundId,
    String? soundName,
    List<bool>? repeatDays,
    String? referralCode,
    ReferralStatus? referralStatus,
    bool? isInProgress,
    bool? isComplete,
  }) =>
      OnboardingState(
        currentPage: currentPage ?? this.currentPage,
        surveyAnswers: surveyAnswers ?? this.surveyAnswers,
        usualWakeTime: usualWakeTime ?? this.usualWakeTime,
        idealWakeTime: idealWakeTime ?? this.idealWakeTime,
        alarmTime: alarmTime ?? this.alarmTime,
        selectedMission: selectedMission ?? this.selectedMission,
        soundId: soundId ?? this.soundId,
        soundName: soundName ?? this.soundName,
        repeatDays: repeatDays ?? this.repeatDays,
        referralCode: referralCode ?? this.referralCode,
        referralStatus: referralStatus ?? this.referralStatus,
        isInProgress: isInProgress ?? this.isInProgress,
        isComplete: isComplete ?? this.isComplete,
      );

  @override
  List<Object?> get props => [
        currentPage,
        surveyAnswers,
        usualWakeTime,
        idealWakeTime,
        alarmTime,
        selectedMission,
        soundId,
        soundName,
        repeatDays,
        referralCode,
        referralStatus,
        isInProgress,
        isComplete,
      ];
}
