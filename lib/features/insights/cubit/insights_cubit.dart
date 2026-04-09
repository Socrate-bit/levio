import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../milestones/services/streak_service.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../../wakeup/services/history_service.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit() : super(const InsightsState());

  Future<void> load() async {
    await _loadForRange(state.range);
  }

  Future<void> changeRange(InsightsRange range) async {
    await _loadForRange(range);
  }

  Future<void> _loadForRange(InsightsRange range) async {
    emit(state.copyWith(loading: true, range: range));
    try {
      final profile = await StreakService.getProfile();

      // Determine date range
      final now = DateTime.now();
      final DateTime? since = switch (range) {
        InsightsRange.week => _startOfWeek(now),
        InsightsRange.month => DateTime(now.year, now.month, 1),
        InsightsRange.allTime => null,
      };

      final sessions = since != null
          ? await HistoryService.getSessions(limit: 500, since: since)
          : await HistoryService.getSessions(limit: 500);

      // Week dots (always for current week regardless of range)
      final weekSessions = await HistoryService.getSessionsThisWeek();
      final weekDays = List<bool>.filled(7, false);
      for (final s in weekSessions) {
        weekDays[s.timestamp.weekday % 7] = true;
      }

      // Avg wake time (clock time, formatted "7:14 AM")
      final avgWakeTime = _computeAvgWakeTime(sessions);

      // Avg response time
      final avgResponseTime = _computeAvgResponseTime(sessions);

      // Favorite mission
      final favoriteMission = _computeFavoriteMission(sessions);

      // Favorite sound
      final favoriteSound = _computeFavoriteSound(sessions);

      // Consistency: distinct wakeup days / days in range * 100
      final consistency = _computeConsistency(sessions, range, now);

      final badgesEarned = profile.earnedBadgeIds.length;
      const totalBadges = 13;

      emit(state.copyWith(
        currentStreak: profile.currentStreak,
        longestStreak: profile.longestStreak,
        weekDays: weekDays,
        badgesEarned: badgesEarned,
        totalBadges: totalBadges,
        avgWakeTime: avgWakeTime,
        avgResponseTime: avgResponseTime,
        favoriteMission: favoriteMission,
        favoriteSound: favoriteSound,
        consistency: consistency,
        range: range,
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
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
    final totalSec = sessions
        .map((s) => s.timeTakenSeconds)
        .reduce((a, b) => a + b);
    final avgSec = totalSec ~/ sessions.length;
    if (avgSec >= 60) {
      final m = avgSec ~/ 60;
      final s = avgSec % 60;
      return '${m}m ${s}s';
    }
    return '${avgSec}s';
  }

  String _computeFavoriteMission(List<WakeupSession> sessions) {
    if (sessions.isEmpty) return '--';
    final counts = <String, int>{};
    for (final s in sessions) {
      if (s.missionType != null) {
        final name = missionInfoFor(s.missionType!).name;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return '--';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _computeFavoriteSound(List<WakeupSession> sessions) {
    if (sessions.isEmpty) return '--';
    final counts = <String, int>{};
    for (final s in sessions) {
      counts[s.soundId] = (counts[s.soundId] ?? 0) + 1;
    }
    if (counts.isEmpty) return '--';
    final topId =
        counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _soundDisplayName(topId);
  }

  double _computeConsistency(
    List<WakeupSession> sessions,
    InsightsRange range,
    DateTime now,
  ) {
    if (sessions.isEmpty) return 0;

    // Count distinct calendar days with a wakeup
    final distinctDays = sessions.map((s) {
      final t = s.timestamp;
      return '${t.year}-${t.month}-${t.day}';
    }).toSet().length;

    final int totalDays = switch (range) {
      InsightsRange.week => 7,
      InsightsRange.month => now.day, // days elapsed so far this month
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

  String _soundDisplayName(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
