import 'package:flutter_bloc/flutter_bloc.dart';

import '../../milestones/services/streak_service.dart';
import '../../wakeup/services/history_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final allSessions = await HistoryService.getSessions(limit: 500);
      final lastSession = allSessions.isEmpty ? null : allSessions.first;
      final totalWakeups = await HistoryService.getTotalWakeups();
      final currentStreak = await StreakService.computeCurrentStreak(allSessions);

      // Build week days (Sun–Sat): which days this week had wakeups
      final weekSessions = await HistoryService.getSessionsThisWeek();
      final weekDays = List<bool>.filled(7, false);
      for (final s in weekSessions) {
        weekDays[s.timestamp.weekday % 7] = true;
      }

      emit(state.copyWith(
        currentStreak: currentStreak,
        weekDays: weekDays,
        lastSession: lastSession,
        totalWakeups: totalWakeups,
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }
}
