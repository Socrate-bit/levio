import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../milestones/models/badge_model.dart';
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
  InsightsRange _range = InsightsRange.week;

  /// How many trailing weeks the streak heatmap spans.
  static const int _heatmapWeeks = 15;

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
    if (_range == range) return;
    _range = range;
    await _recompute();
  }

  Future<void> _recompute() async {
    if (isClosed) return;
    final range = _range;
    final now = DateTime.now();

    final DateTime? since = switch (range) {
      InsightsRange.week => _startOfWeek(now),
      InsightsRange.month => DateTime(now.year, now.month, 1),
      InsightsRange.allTime => null,
    };

    final sessions = since != null
        ? _allSessions.where((s) => s.timestamp.isAfter(since)).toList()
        : _allSessions;

    // Split by alarm kind so timing stats read separately for sleep and wake.
    final wake = sessions.where((s) => !s.isSleep).toList();
    final sleep = sessions.where((s) => s.isSleep).toList();

    // Single streak walk gives both the count and the freeze days the activity
    // heatmap needs. Sessions include incomplete ones so misses are seen.
    final streakResult = StreakService.computeStreak(sessions: _allSessions);
    final currentStreak = streakResult.streak;

    final completed = sessions.where((s) => s.completed).length;
    final missed = sessions
        .where((s) =>
            !s.completed && !s.screenTimeDisabled && s.alarmId != null)
        .length;
    final total = completed + missed;

    emit(state.copyWith(
      currentStreak: currentStreak,
      longestStreak: _profile.longestStreak,
      badgesEarned: _profile.earnedBadgeIds.length,
      totalBadges: 13,
      currentBadge: _computeCurrentBadge(),
      nextBadge: _computeNextBadge(currentStreak),
      successCount: completed,
      successRate: total == 0 ? 0 : completed / total * 100,
      avgWakeTime: _computeAvgClockTime(wake),
      avgSleepTime: _computeAvgClockTime(sleep),
      avgWakeRoutine: _computeAvgRoutine(wake),
      avgSleepRoutine: _computeAvgRoutine(sleep),
      favoriteMission: _computeFavoriteMission(sessions),
      favoriteSound: _computeFavoriteSound(sessions),
      heatmap: _computeHeatmap(now, streakResult.frozenDays),
      progression: _computeProgression(sessions, range, now),
      sessions: sessions,
      totalWakeups: _allSessions.where((s) => s.completed).length,
      range: range,
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

  /// Average time-of-day (12h) across [sessions]. Excludes screen-time-disabled
  /// entries, whose timestamps are unlock moments rather than alarm times.
  ///
  /// Uses a circular mean so times that straddle midnight (e.g. bedtimes at
  /// 23:30 and 00:30) average to ~00:00 rather than midday.
  String _computeAvgClockTime(List<WakeupSession> sessions) {
    final timed = sessions.where((s) => !s.screenTimeDisabled).toList();
    if (timed.isEmpty) return '--:--';
    // Map each minute-of-day onto the unit circle, average, then convert back.
    var sumSin = 0.0;
    var sumCos = 0.0;
    for (final s in timed) {
      final minutes = s.timestamp.hour * 60 + s.timestamp.minute;
      final angle = minutes / 1440 * 2 * pi;
      sumSin += sin(angle);
      sumCos += cos(angle);
    }
    var avgAngle = atan2(sumSin, sumCos);
    if (avgAngle < 0) avgAngle += 2 * pi;
    final avgMin = (avgAngle / (2 * pi) * 1440).round() % 1440;
    final h24 = avgMin ~/ 60;
    final m = (avgMin % 60).toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:$m $period';
  }

  /// Average mission/routine duration across completed [sessions] only, so
  /// missed alarms (0s) don't drag the average down.
  String _computeAvgRoutine(List<WakeupSession> sessions) {
    final done = sessions.where((s) => s.completed).toList();
    if (done.isEmpty) return '--';
    final totalSec =
        done.map((s) => s.timeTakenSeconds).reduce((a, b) => a + b);
    final avgSec = totalSec ~/ done.length;
    if (avgSec >= 60) {
      final m = avgSec ~/ 60;
      final s = avgSec % 60;
      return '${m}m ${s}s';
    }
    return '${avgSec}s';
  }

  /// The highest streak badge the user has already earned, or null if none.
  BadgeModel? _computeCurrentBadge() {
    BadgeModel? latest;
    for (final badge in buildStreakBadges()) {
      if (_profile.earnedBadgeIds.contains(badge.id)) latest = badge;
    }
    return latest;
  }

  /// The next streak badge the user hasn't reached, or null once all are earned.
  BadgeModel? _computeNextBadge(int currentStreak) {
    for (final badge in buildStreakBadges()) {
      if ((badge.requiredDays ?? 0) > currentStreak) return badge;
    }
    return null;
  }

  /// Returns the raw MissionType.name (e.g. 'pushUps') or '--' if none.
  String _computeFavoriteMission(List<WakeupSession> sessions) {
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

  /// Per-day activity for the trailing [_heatmapWeeks] weeks, aligned to whole
  /// weeks (Sunday-start). Each day is classed win / freeze / loss / none using
  /// the same rules as the home week view; [frozenDays] comes from the streak
  /// walk. Future days of the current week stay empty so the grid is rectangular.
  List<HeatmapDay> _computeHeatmap(DateTime now, Set<String> frozenDays) {
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = _startOfWeek(today);
    final start =
        startOfThisWeek.subtract(Duration(days: (_heatmapWeeks - 1) * 7));

    final completedDays = <String>{};
    final disabledDays = <String>{};
    final missedAlarmDays = <String>{};
    for (final s in _allSessions) {
      if (s.timestamp.isBefore(start)) continue;
      final key = _dayKey(s.timestamp);
      if (s.completed) {
        completedDays.add(key);
      } else if (s.screenTimeDisabled) {
        disabledDays.add(key);
      } else if (s.alarmId != null) {
        missedAlarmDays.add(key);
      }
    }

    final days = <HeatmapDay>[];
    for (var i = 0; i < _heatmapWeeks * 7; i++) {
      final date = start.add(Duration(days: i));
      final key = _dayKey(date);

      final DayStatus status;
      if (frozenDays.contains(key)) {
        status = DayStatus.frozen;
      } else if (completedDays.contains(key) && !disabledDays.contains(key)) {
        // Disabling screen time forces the day to a miss even if completed.
        status = DayStatus.done;
      } else if (disabledDays.contains(key) || missedAlarmDays.contains(key)) {
        status = DayStatus.missed;
      } else {
        status = DayStatus.none;
      }
      days.add(HeatmapDay(date: date, status: status));
    }
    return days;
  }

  /// Success-rate buckets over the selected range: daily (week), weekly (month),
  /// or monthly (all-time). Buckets with no alarms carry a null rate.
  List<ProgressPoint> _computeProgression(
    List<WakeupSession> sessions,
    InsightsRange range,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);

    List<DateTime> bucketStarts;
    DateTime Function(DateTime) bucketOf;

    switch (range) {
      case InsightsRange.week:
        // The 7 days of the current calendar week (Sunday-start), matching the
        // `since` filter in _recompute so no bucket predates the kept sessions.
        final startOfWeek = _startOfWeek(today);
        bucketStarts = [
          for (var i = 0; i < 7; i++) startOfWeek.add(Duration(days: i)),
        ];
        bucketOf = (d) => DateTime(d.year, d.month, d.day);
      case InsightsRange.month:
        final firstWeek = _startOfWeek(DateTime(now.year, now.month, 1));
        final thisWeek = _startOfWeek(today);
        bucketStarts = [];
        for (var w = firstWeek;
            !w.isAfter(thisWeek);
            w = w.add(const Duration(days: 7))) {
          bucketStarts.add(w);
        }
        bucketOf = (d) => _startOfWeek(DateTime(d.year, d.month, d.day));
      case InsightsRange.allTime:
        final oldest = sessions.isEmpty
            ? DateTime(now.year, now.month, 1)
            : DateTime(
                sessions.last.timestamp.year,
                sessions.last.timestamp.month,
                1,
              );
        bucketStarts = [];
        for (var m = oldest;
            !m.isAfter(DateTime(now.year, now.month, 1));
            m = DateTime(m.year, m.month + 1, 1)) {
          bucketStarts.add(m);
        }
        // Cap to the most recent 12 months so the axis stays readable.
        if (bucketStarts.length > 12) {
          bucketStarts = bucketStarts.sublist(bucketStarts.length - 12);
        }
        bucketOf = (d) => DateTime(d.year, d.month, 1);
    }

    final completed = <DateTime, int>{for (final b in bucketStarts) b: 0};
    final missed = <DateTime, int>{for (final b in bucketStarts) b: 0};
    for (final s in sessions) {
      final b = bucketOf(s.timestamp);
      if (!completed.containsKey(b)) continue;
      if (s.completed) {
        completed[b] = completed[b]! + 1;
      } else if (!s.screenTimeDisabled && s.alarmId != null) {
        missed[b] = missed[b]! + 1;
      }
    }

    return [
      for (final b in bucketStarts)
        ProgressPoint(
          date: b,
          rate: (completed[b]! + missed[b]!) == 0
              ? null
              : completed[b]! / (completed[b]! + missed[b]!) * 100,
        ),
    ];
  }

  // Must match StreakService's date-key format so frozenDays lookups line up.
  String _dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  DateTime _startOfWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }
}
