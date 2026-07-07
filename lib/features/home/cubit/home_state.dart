import '../../milestones/services/streak_service.dart';
import '../../wakeup/models/wakeup_session.dart';

export '../../milestones/services/streak_service.dart' show DayStatus;

class HomeState {
  final int currentStreak;
  final int longestStreak;
  final List<DayStatus> weekDays; // Sun–Sat
  final List<String> earnedBadgeIds;
  final WakeupSession? lastSession;
  final int totalWakeups;
  // Alarm ids that already have a completed session today (e.g. via "Start now"
  // early completion). Used to hide "Start now" and skip today's fire on Home.
  final Set<String> completedAlarmIdsToday;
  final bool loading;

  const HomeState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weekDays = const [
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
    ],
    this.earnedBadgeIds = const [],
    this.lastSession,
    this.totalWakeups = 0,
    this.completedAlarmIdsToday = const {},
    this.loading = true,
  });

  HomeState copyWith({
    int? currentStreak,
    int? longestStreak,
    List<DayStatus>? weekDays,
    List<String>? earnedBadgeIds,
    WakeupSession? lastSession,
    bool clearLastSession = false,
    int? totalWakeups,
    Set<String>? completedAlarmIdsToday,
    bool? loading,
  }) =>
      HomeState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        weekDays: weekDays ?? this.weekDays,
        earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
        lastSession: clearLastSession ? null : lastSession ?? this.lastSession,
        totalWakeups: totalWakeups ?? this.totalWakeups,
        completedAlarmIdsToday:
            completedAlarmIdsToday ?? this.completedAlarmIdsToday,
        loading: loading ?? this.loading,
      );
}
