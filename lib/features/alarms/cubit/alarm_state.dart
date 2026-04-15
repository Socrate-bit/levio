import 'package:equatable/equatable.dart';

import '../../missions/models/mission_config.dart';

enum MathDifficulty { easy, medium, hard }

/// Local model for a scheduled alarm.
class AppAlarmEntry extends Equatable {
  final String id;
  final DateTime dateTime;
  final List<MissionConfig> missions; // up to 3
  final String name;
  final String soundId;
  final List<bool> repeatDays; // Sun=0 … Sat=6
  final bool isEnabled;
  final bool isOneTime;

  const AppAlarmEntry({
    required this.id,
    required this.dateTime,
    this.missions = const [],
    this.name = '',
    this.soundId = 'default',
    this.repeatDays = const [false, true, true, true, true, true, false],
    this.isEnabled = true,
    this.isOneTime = false,
  });

  AppAlarmEntry copyWith({
    String? id,
    DateTime? dateTime,
    List<MissionConfig>? missions,
    String? name,
    String? soundId,
    List<bool>? repeatDays,
    bool? isEnabled,
    bool? isOneTime,
  }) =>
      AppAlarmEntry(
        id: id ?? this.id,
        dateTime: dateTime ?? this.dateTime,
        missions: missions ?? this.missions,
        name: name ?? this.name,
        soundId: soundId ?? this.soundId,
        repeatDays: repeatDays ?? this.repeatDays,
        isEnabled: isEnabled ?? this.isEnabled,
        isOneTime: isOneTime ?? this.isOneTime,
      );

  @override
  List<Object?> get props => [
        id,
        dateTime,
        missions,
        name,
        soundId,
        repeatDays,
        isEnabled,
        isOneTime,
      ];
}

class AlarmState extends Equatable {
  final List<AppAlarmEntry> alarms;
  const AlarmState({this.alarms = const []});

  AlarmState copyWith({List<AppAlarmEntry>? alarms}) =>
      AlarmState(alarms: alarms ?? this.alarms);

  @override
  List<Object?> get props => [alarms];
}
