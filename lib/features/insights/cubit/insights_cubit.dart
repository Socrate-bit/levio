import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../milestones/services/streak_service.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../../wakeup/services/history_service.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  StreamSubscription<List<WakeupSession>>? _sessionsSub;
  StreamSubscription<StreakProfile>? _profileSub;
  Completer<void>? _loadCompleter;

  List<WakeupSession> _allSessions = [];
  StreakProfile _profile = const StreakProfile();
  bool _sessionsReady = false;
  bool _profileReady = false;

  InsightsCubit() : super(const InsightsState()) {
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

  /// Called by [RefreshIndicator]. Re-subscribes so Firestore fires a fresh
  /// snapshot; the returned future completes once the first recompute finishes.
  Future<void> load() {
    _loadCompleter?.complete();
    _loadCompleter = Completer<void>();
    emit(state.copyWith(loading: true));
    _cancelSubs();
    _subscribe();
    return _loadCompleter!.future;
  }

  Future<void> changeRange(InsightsRange range) async {
    if (state.range == range) return;
    emit(state.copyWith(range: range));
    await _recompute();
  }

  Future<void> _recompute() async {
    if (isClosed) return;
    final range = state.range;
    final now = DateTime.now();

    final DateTime? since = switch (range) {
      InsightsRange.week => _startOfWeek(now),
      InsightsRange.month => DateTime(now.year, now.month, 1),
      InsightsRange.allTime => null,
    };

    final sessions = since != null
        ? _allSessions.where((s) => s.timestamp.isAfter(since)).toList()
        : _allSessions;

    // Week dots always reflect the current calendar week
    final startOfWeek = _startOfWeek(now);
    final weekSessions =
        _allSessions.where((s) => s.timestamp.isAfter(startOfWeek)).toList();
    final weekDays = List<bool>.filled(7, false);
    for (final s in weekSessions) {
      weekDays[s.timestamp.weekday % 7] = true;
    }

    final currentStreak =
        await StreakService.computeCurrentStreak(_allSessions);

    if (isClosed) return;

    // Total completed wakeups for numbering
    final totalWakeups = _allSessions.where((s) => s.completed).length;

    emit(state.copyWith(
      currentStreak: currentStreak,
      longestStreak: _profile.longestStreak,
      weekDays: weekDays,
      badgesEarned: _profile.earnedBadgeIds.length,
      totalBadges: 13,
      avgWakeTime: _computeAvgWakeTime(sessions),
      avgResponseTime: _computeAvgResponseTime(sessions),
      favoriteMission: _computeFavoriteMission(sessions),
      favoriteSound: _computeFavoriteSound(sessions),
      consistency: _computeConsistency(sessions, range, now),
      sessions: sessions,
      totalWakeups: totalWakeups,
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

  // ---------------------------------------------------------------------------
  // Computation helpers
  // ---------------------------------------------------------------------------

  String _computeAvgWakeTime(List<WakeupSession> sessions) {
    if (sessions.isEmpty) return '--:--';
    final totalMinutes = sessions
        .map((s) => s.timestamp.hour * 60 + s.timestamp.minute)
        .reduce((a, b) => a + b);
    final avgMin = totalMinutes ~/ sessions.length;
    final h24 = avgMin ~/ 60;
    final m = (avgMin % 60).toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:$m $period';
  }

  String _computeAvgResponseTime(List<WakeupSession> sessions) {
    if (sessions.isEmpty) return '--';
    final totalSec =
        sessions.map((s) => s.timeTakenSeconds).reduce((a, b) => a + b);
    final avgSec = totalSec ~/ sessions.length;
    if (avgSec >= 60) {
      final m = avgSec ~/ 60;
      final s = avgSec % 60;
      return '${m}m ${s}s';
    }
    return '${avgSec}s';
  }

  /// Returns the raw MissionType.name (e.g. 'pushUps') or '--' if none.
  String _computeFavoriteMission(List<WakeupSession> sessions) {
    if (sessions.isEmpty) return '--';
    final counts = <String, int>{};
    for (final s in sessions) {
      if (s.missionType != null) {
        final key = s.missionType!.name;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '--';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Returns the raw sound ID (e.g. 'default') or '--' if none.
  String _computeFavoriteSound(List<WakeupSession> sessions) {
    if (sessions.isEmpty) return '--';
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.soundId] = (counts[s.soundId] ?? 0) + 1;
    }
    if (counts.isEmpty) return '--';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _computeConsistency(
    List<WakeupSession> sessions,
    InsightsRange range,
    DateTime now,
  ) {
    if (sessions.isEmpty) return 0;

    final distinctDays = sessions.map((s) {
      final t = s.timestamp;
      return '${t.year}-${t.month}-${t.day}';
    }).toSet().length;

    final int totalDays = switch (range) {
      InsightsRange.week => 7,
      InsightsRange.month => now.day,
      InsightsRange.allTime => () {
          if (sessions.isEmpty) return 1;
          final oldest = sessions.last.timestamp;
          return max(1, now.difference(oldest).inDays + 1);
        }(),
    };

    return min(distinctDays / totalDays * 100, 100);
  }

  DateTime _startOfWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

}
