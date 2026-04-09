import 'package:flutter_bloc/flutter_bloc.dart';

import '../../milestones/services/streak_service.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/services/history_service.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit() : super(const InsightsState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final profile = await StreakService.getProfile();
      final sessions = await HistoryService.getSessions(limit: 100);
      final weekSessions = await HistoryService.getSessionsThisWeek();

      // Week days
      final weekDays = List<bool>.filled(7, false);
      for (final s in weekSessions) {
        weekDays[s.timestamp.weekday % 7] = true;
      }

      // Avg wake time
      String avgWakeTime = '--:--';
      if (sessions.isNotEmpty) {
        final totalMinutes = sessions
            .map((s) => s.timestamp.hour * 60 + s.timestamp.minute)
            .reduce((a, b) => a + b);
        final avgMin = totalMinutes ~/ sessions.length;
        final h = avgMin ~/ 60;
        final m = (avgMin % 60).toString().padLeft(2, '0');
        avgWakeTime = '$h:$m';
      }

      // Avg response time
      String avgResponseTime = '--';
      if (sessions.isNotEmpty) {
        final totalSec = sessions
            .map((s) => s.timeTakenSeconds)
            .reduce((a, b) => a + b);
        final avgSec = totalSec ~/ sessions.length;
        avgResponseTime = '${avgSec}s';
      }

      // Favorite mission
      String favoriteMission = '--';
      if (sessions.isNotEmpty) {
        final missionCounts = <String, int>{};
        for (final s in sessions) {
          if (s.missionType != null) {
            final name = missionInfoFor(s.missionType!).name;
            missionCounts[name] = (missionCounts[name] ?? 0) + 1;
          }
        }
        if (missionCounts.isNotEmpty) {
          favoriteMission = missionCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }

      // Favorite sound
      String favoriteSound = '--';
      if (sessions.isNotEmpty) {
        final soundCounts = <String, int>{};
        for (final s in sessions) {
          soundCounts[s.soundId] = (soundCounts[s.soundId] ?? 0) + 1;
        }
        if (soundCounts.isNotEmpty) {
          final topId = soundCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          favoriteSound = _soundDisplayName(topId);
        }
      }

      // Consistency score (0–100) based on streak + session regularity
      double consistency = 0;
      if (sessions.length >= 3) {
        final streak = profile.currentStreak;
        if (streak >= 30) {
          consistency = 100;
        } else if (streak >= 14) {
          consistency = 80;
        } else if (streak >= 7) {
          consistency = 60;
        } else if (streak >= 3) {
          consistency = 40;
        } else {
          consistency = 15;
        }
      }

      final badgesEarned = profile.earnedBadgeIds.length;
      const totalBadges = 13; // 7 streak + 6 achievement

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
        loading: false,
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  String _soundDisplayName(String id) {
    return id
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
