import '../../alarms/cubit/alarm_state.dart';
import '../../wakeup/models/wakeup_session.dart';

class HomeState {
  final int currentStreak;
  final List<bool> weekDays; // Sun–Sat, true = woken up
  final AppAlarmEntry? nextAlarm;
  final WakeupSession? lastSession;
  final int totalWakeups;
  final bool loading;

  const HomeState({
    this.currentStreak = 0,
    this.weekDays = const [false, false, false, false, false, false, false],
    this.nextAlarm,
    this.lastSession,
    this.totalWakeups = 0,
    this.loading = true,
  });

  HomeState copyWith({
    int? currentStreak,
    List<bool>? weekDays,
    AppAlarmEntry? nextAlarm,
    bool clearNextAlarm = false,
    WakeupSession? lastSession,
    bool clearLastSession = false,
    int? totalWakeups,
    bool? loading,
  }) =>
      HomeState(
        currentStreak: currentStreak ?? this.currentStreak,
        weekDays: weekDays ?? this.weekDays,
        nextAlarm: clearNextAlarm ? null : nextAlarm ?? this.nextAlarm,
        lastSession:
            clearLastSession ? null : lastSession ?? this.lastSession,
        totalWakeups: totalWakeups ?? this.totalWakeups,
        loading: loading ?? this.loading,
      );
}
