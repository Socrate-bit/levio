import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../milestones/services/streak_service.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../../wakeup/services/history_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  StreamSubscription<List<WakeupSession>>? _sessionsSub;
  StreamSubscription<StreakProfile>? _profileSub;
  Completer<void>? _loadCompleter;

  List<WakeupSession> _allSessions = [];
  StreakProfile _profile = const StreakProfile();
  bool _sessionsReady = false;
  bool _profileReady = false;

  HomeCubit() : super(const HomeState()) {
    _subscribe();
  }

  void _subscribe() {
    _sessionsReady = false;
    _profileReady = false;

    _sessionsSub = HistoryService.watchSessions(limit: 500).listen((sessions) {
      _allSessions = sessions;
      _sessionsReady = true;
      if (_profileReady) _recompute();
    });

    _profileSub = StreakService.watchProfile().listen((profile) {
      _profile = profile;
      _profileReady = true;
      if (_sessionsReady) _recompute();
    });
  }

  Future<void> load() {
    _loadCompleter?.complete();
    _loadCompleter = Completer<void>();
    emit(state.copyWith(loading: true));
    _cancelSubs();
    _subscribe();
    return _loadCompleter!.future;
  }

  Future<void> _recompute() async {
    if (isClosed) return;

    final lastSession = _allSessions.isEmpty ? null : _allSessions.first;
    final firstAlarmDate = await StreakService.getFirstAlarmCreatedDate();
    final currentStreak =
        await StreakService.computeCurrentStreak(_allSessions, firstAlarmDate);

    final now = DateTime.now();
    final startOfWeek = _startOfWeek(now);
    final todayIndex = now.weekday % 7; // 0=Sun

    // Determine the first day index this week that counts (after first alarm creation)
    int firstCountableIndex = 0;
    if (firstAlarmDate != null && firstAlarmDate.isAfter(startOfWeek)) {
      firstCountableIndex = firstAlarmDate.weekday % 7;
    }

    final weekDays = List<DayStatus>.filled(7, DayStatus.none);
    for (final s in _allSessions) {
      if (s.timestamp.isAfter(startOfWeek)) {
        weekDays[s.timestamp.weekday % 7] = DayStatus.done;
      }
    }

    // Count missed past days this week (skip future days and days before first alarm)
    int missedCount = 0;
    for (int i = firstCountableIndex; i <= todayIndex; i++) {
      if (weekDays[i] == DayStatus.none) missedCount++;
    }

    // If ≤2 misses, mark them as frozen (streak held)
    if (missedCount <= 2) {
      for (int i = firstCountableIndex; i <= todayIndex; i++) {
        if (weekDays[i] == DayStatus.none) weekDays[i] = DayStatus.frozen;
      }
    }

    if (isClosed) return;

    emit(state.copyWith(
      currentStreak: currentStreak,
      weekDays: weekDays,
      lastSession: lastSession,
      clearLastSession: lastSession == null,
      totalWakeups: _profile.totalWakeups,
      loading: false,
    ));

    _loadCompleter?.complete();
    _loadCompleter = null;
  }

  void _cancelSubs() {
    _sessionsSub?.cancel();
    _profileSub?.cancel();
    _sessionsSub = null;
    _profileSub = null;
  }

  @override
  Future<void> close() {
    _cancelSubs();
    _loadCompleter?.complete();
    _loadCompleter = null;
    return super.close();
  }

  DateTime _startOfWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }
}
