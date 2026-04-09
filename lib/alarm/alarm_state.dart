import 'package:equatable/equatable.dart';

/// Local model for a scheduled alarm (flutter_alarmkit returns UUID strings,
/// not rich objects, so we track dateTime ourselves).
class AppAlarmEntry extends Equatable {
  final String id;
  final DateTime dateTime;

  const AppAlarmEntry({required this.id, required this.dateTime});

  @override
  List<Object?> get props => [id, dateTime];
}

class AlarmState extends Equatable {
  final List<AppAlarmEntry> alarms;
  const AlarmState({this.alarms = const []});

  AlarmState copyWith({List<AppAlarmEntry>? alarms}) =>
      AlarmState(alarms: alarms ?? this.alarms);

  @override
  List<Object?> get props => [alarms];
}
