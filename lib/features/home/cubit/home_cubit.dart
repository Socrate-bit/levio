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

  void _recompute() {
    if (isClosed) return;

    final lastSession = _allSessions.isEmpty ? null : _allSessions.first;
    final result = StreakService.computeStreak(sessions: _allSessions);

    emit(state.copyWith(
      currentStreak: result.streak,
      longestStreak: _profile.longestStreak,
      weekDays: result.weekDays,
      earnedBadgeIds: _profile.earnedBadgeIds,
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
}
