import '../../wakeup/models/wakeup_session.dart';

enum DayStatus { none, done, frozen }

class HomeState {
  final int currentStreak;
  final List<DayStatus> weekDays; // Sun–Sat
  final WakeupSession? lastSession;
  final int totalWakeups;
  final bool loading;

  const HomeState({
    this.currentStreak = 0,
    this.weekDays = const [
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
      DayStatus.none,
    ],
    this.lastSession,
    this.totalWakeups = 0,
    this.loading = true,
  });

  HomeState copyWith({
    int? currentStreak,
    List<DayStatus>? weekDays,
    WakeupSession? lastSession,
    bool clearLastSession = false,
    int? totalWakeups,
    bool? loading,
  }) =>
      HomeState(
        currentStreak: currentStreak ?? this.currentStreak,
        weekDays: weekDays ?? this.weekDays,
        lastSession: clearLastSession ? null : lastSession ?? this.lastSession,
        totalWakeups: totalWakeups ?? this.totalWakeups,
        loading: loading ?? this.loading,
      );
}
