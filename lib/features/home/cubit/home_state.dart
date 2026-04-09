import '../../wakeup/models/wakeup_session.dart';

class HomeState {
  final int currentStreak;
  final List<bool> weekDays; // Sun–Sat, true = woken up
  final WakeupSession? lastSession;
  final int totalWakeups;
  final bool loading;

  const HomeState({
    this.currentStreak = 0,
    this.weekDays = const [false, false, false, false, false, false, false],
    this.lastSession,
    this.totalWakeups = 0,
    this.loading = true,
  });

  HomeState copyWith({
    int? currentStreak,
    List<bool>? weekDays,
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
