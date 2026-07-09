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
  final DateTime createdAt;
  final bool disabledBySubscription;

  /// Sleep (bedtime) alarm vs the default wake-up alarm.
  final bool isSleep;

  /// Gentle ring: a single AlarmKit alert with no burst cascade. Sleep-only.
  final bool gentle;

  /// Whether to fire a pre-alarm reminder notification. Sleep-only.
  final bool reminderEnabled;

  /// How many minutes before the alarm the reminder fires.
  final int reminderMinutesBefore;

  /// Whether a Spin to Win bonus wheel appears after the dismiss mission
  /// completes. At most one alarm per user may have this enabled.
  final bool spinToWin;

  AppAlarmEntry({
    required this.id,
    required this.dateTime,
    this.missions = const [],
    this.name = '',
    this.soundId = 'default',
    this.repeatDays = const [false, true, true, true, true, true, false],
    this.isEnabled = true,
    this.isOneTime = false,
    this.disabledBySubscription = false,
    this.isSleep = false,
    this.gentle = false,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 15,
    this.spinToWin = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  AppAlarmEntry copyWith({
    String? id,
    DateTime? dateTime,
    List<MissionConfig>? missions,
    String? name,
    String? soundId,
    List<bool>? repeatDays,
    bool? isEnabled,
    bool? isOneTime,
    bool? disabledBySubscription,
    bool? isSleep,
    bool? gentle,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    bool? spinToWin,
    DateTime? createdAt,
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
        disabledBySubscription:
            disabledBySubscription ?? this.disabledBySubscription,
        isSleep: isSleep ?? this.isSleep,
        gentle: gentle ?? this.gentle,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderMinutesBefore:
            reminderMinutesBefore ?? this.reminderMinutesBefore,
        spinToWin: spinToWin ?? this.spinToWin,
        createdAt: createdAt ?? this.createdAt,
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
        disabledBySubscription,
        isSleep,
        gentle,
        reminderEnabled,
        reminderMinutesBefore,
        spinToWin,
        createdAt,
      ];
}

extension AppAlarmEntryFire on AppAlarmEntry {
  /// Next real fire time in the future, respecting [repeatDays]/[isOneTime].
  /// Returns null if the alarm has no upcoming fire.
  DateTime? nextFireAt(DateTime now) {
    if (!isEnabled) return null;
    if (isOneTime) {
      return dateTime.isAfter(now) ? dateTime : null;
    }
    // Scan up to 7 days ahead; day index uses Sun=0 … Sat=6.
    for (int i = 0; i < 7; i++) {
      final candidateDay = DateTime(now.year, now.month, now.day).add(
        Duration(days: i),
      );
      final dayIndex = candidateDay.weekday % 7;
      if (repeatDays.length > dayIndex && repeatDays[dayIndex]) {
        final candidate = DateTime(
          candidateDay.year,
          candidateDay.month,
          candidateDay.day,
          dateTime.hour,
          dateTime.minute,
        );
        if (candidate.isAfter(now)) return candidate;
      }
    }
    return null;
  }
}

extension AppAlarmEntryRingLock on AppAlarmEntry {
  /// Fire time of the ring currently within its lock window: the most recent
  /// scheduled fire on an active day such that [now] is in [start, start+window).
  /// Returns null if no ring is currently within its window.
  DateTime? activeRingStart(
    DateTime now, {
    Duration window = const Duration(minutes: 30),
  }) {
    // A disabled alarm never fires, so it is never lock-eligible.
    if (!isEnabled) return null;
    if (isOneTime) {
      final start = dateTime;
      return (!now.isBefore(start) && now.isBefore(start.add(window)))
          ? start
          : null;
    }
    // Check today and yesterday so windows crossing midnight still lock.
    for (int i = 0; i <= 1; i++) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayIndex = day.weekday % 7;
      if (repeatDays.length > dayIndex && repeatDays[dayIndex]) {
        final start = DateTime(
          day.year,
          day.month,
          day.day,
          dateTime.hour,
          dateTime.minute,
        );
        if (!now.isBefore(start) && now.isBefore(start.add(window))) {
          return start;
        }
      }
    }
    return null;
  }
}

class AlarmState extends Equatable {
  final List<AppAlarmEntry> alarms;
  final bool isLoading;
  const AlarmState({this.alarms = const [], this.isLoading = false});

  AlarmState copyWith({List<AppAlarmEntry>? alarms, bool? isLoading}) =>
      AlarmState(
        alarms: alarms ?? this.alarms,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [alarms, isLoading];
}
