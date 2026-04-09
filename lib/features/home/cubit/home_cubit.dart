import 'package:flutter_bloc/flutter_bloc.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../milestones/services/streak_service.dart';
import '../../wakeup/services/history_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  Future<void> load(AlarmCubit alarmCubit) async {
    emit(state.copyWith(loading: true));
    try {
      final profile = await StreakService.getProfile();
      final lastSession = await HistoryService.getLastSession();
      final totalWakeups = await HistoryService.getTotalWakeups();

      // Build week days (Sun–Sat): which days this week had wakeups
      final weekSessions = await HistoryService.getSessionsThisWeek();
      final weekDays = List<bool>.filled(7, false);
      for (final s in weekSessions) {
        weekDays[s.timestamp.weekday % 7] = true;
      }

      // Find next upcoming alarm
      final alarms = alarmCubit.state.alarms;
      alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final next = alarms.where((a) => a.isEnabled).firstOrNull;

      emit(state.copyWith(
        currentStreak: profile.currentStreak,
        weekDays: weekDays,
        nextAlarm: next,
        lastSession: lastSession,
        totalWakeups: totalWakeups,
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }
}
