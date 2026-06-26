import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A single screen-time blocking window. Apps are blocked on the repeat days
/// between [startHour]:[startMinute] and [endHour]:[endMinute]. Windows may
/// wrap past midnight (e.g. 22:30 → 07:00).
class ScreenTimeSchedule extends Equatable {
  final String id;
  final bool enabled;

  /// Length 7, index 0 = Sunday … 6 = Saturday (matches the alarm convention).
  final List<bool> repeatDays;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const ScreenTimeSchedule({
    required this.id,
    this.enabled = true,
    required this.repeatDays,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  /// Creates a schedule with a fresh id and the standard overnight default
  /// (every day, 22:00 → 07:00).
  factory ScreenTimeSchedule.create() => ScreenTimeSchedule(
        id: const Uuid().v4(),
        repeatDays: List.filled(7, true),
        startHour: 22,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
      );

  int get _startMinutes => startHour * 60 + startMinute;
  int get _endMinutes => endHour * 60 + endMinute;

  /// Whether [now] falls inside this schedule's active window, respecting the
  /// repeat days and overnight wrap. For an overnight window the "day" the
  /// window belongs to is the day it *starts* on, so an early-morning instant
  /// (before the end time) is matched against the previous day's repeat flag.
  bool isActiveAt(DateTime now) {
    if (!enabled) return false;
    final start = _startMinutes;
    final end = _endMinutes;
    final nowMinutes = now.hour * 60 + now.minute;
    final todayFlag = repeatDays[now.weekday % 7]; // weekday: Mon=1..Sun=7

    if (start <= end) {
      // Same-day window.
      return todayFlag && nowMinutes >= start && nowMinutes < end;
    }
    // Overnight window: either the evening part on the start day, or the
    // early-morning part owned by the previous day.
    if (nowMinutes >= start) return todayFlag;
    if (nowMinutes < end) {
      final yesterday = now.subtract(const Duration(days: 1));
      return repeatDays[yesterday.weekday % 7];
    }
    return false;
  }

  /// The next [DateTime] at which this schedule's window ends, given that it is
  /// currently active. Used for the "Active until HH:MM" status.
  DateTime endAfter(DateTime now) {
    final end = _endMinutes;
    final start = _startMinutes;
    final todayEnd = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute,
    );
    if (start <= end) return todayEnd;
    // Overnight: if we're in the evening part, the end is tomorrow morning.
    final nowMinutes = now.hour * 60 + now.minute;
    if (nowMinutes >= start) return todayEnd.add(const Duration(days: 1));
    return todayEnd;
  }

  /// The next [DateTime] at which this schedule's window starts, strictly after
  /// [now]. Returns null if no repeat day is enabled. Used for "Active in Xh".
  DateTime? nextStartAfter(DateTime now) {
    if (!enabled || repeatDays.every((d) => !d)) return null;
    for (var i = 0; i < 8; i++) {
      final day = now.add(Duration(days: i));
      if (!repeatDays[day.weekday % 7]) continue;
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        startHour,
        startMinute,
      );
      if (start.isAfter(now)) return start;
    }
    return null;
  }

  ScreenTimeSchedule copyWith({
    bool? enabled,
    List<bool>? repeatDays,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return ScreenTimeSchedule(
      id: id,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'repeatDays': repeatDays,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory ScreenTimeSchedule.fromJson(Map<String, dynamic> json) {
    return ScreenTimeSchedule(
      id: json['id'] as String? ?? const Uuid().v4(),
      enabled: json['enabled'] as bool? ?? true,
      repeatDays: List<bool>.from(
        json['repeatDays'] as List? ?? List.filled(7, true),
      ),
      startHour: json['startHour'] as int? ?? 22,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 7,
      endMinute: json['endMinute'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        enabled,
        repeatDays,
        startHour,
        startMinute,
        endHour,
        endMinute,
      ];
}
