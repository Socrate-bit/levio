import '../../milestones/models/badge_model.dart';
import '../../milestones/services/streak_service.dart';
import '../../wakeup/models/wakeup_session.dart';

enum InsightsRange { week, month, allTime }

/// A single calendar day in the streak heatmap. [status] mirrors the home week
/// view: [DayStatus.done] = win (blue), [DayStatus.frozen] = freeze,
/// [DayStatus.missed] = loss (red), [DayStatus.none] = no alarm.
class HeatmapDay {
  final DateTime date;
  final DayStatus status;

  const HeatmapDay({
    required this.date,
    this.status = DayStatus.none,
  });
}

/// A single bucket on the success-rate progression chart. [date] is the bucket
/// start; the widget formats the axis label from it (day / week / month) using
/// l10n, so the cubit stays localization-free.
class ProgressPoint {
  final DateTime date;

  /// Success rate for the bucket, 0–100. Null when the bucket had no alarms.
  final double? rate;

  const ProgressPoint({required this.date, this.rate});
}

class InsightsState {
  final int currentStreak;
  final int longestStreak;
  final int badgesEarned;
  final int totalBadges;

  /// Highest streak badge already earned, or null before the first is reached.
  final BadgeModel? currentBadge;

  /// Next unearned streak badge, or null once every streak badge is earned.
  final BadgeModel? nextBadge;

  final int successCount;
  final double successRate; // 0–100

  final String avgWakeTime;
  final String avgSleepTime;
  final String avgWakeRoutine;
  final String avgSleepRoutine;

  final String favoriteMission;
  final String favoriteSound;

  final List<HeatmapDay> heatmap;
  final List<ProgressPoint> progression;

  final InsightsRange range;
  final bool loading;
  final List<WakeupSession> sessions;
  final int totalWakeups;

  const InsightsState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badgesEarned = 0,
    this.totalBadges = 13,
    this.currentBadge,
    this.nextBadge,
    this.successCount = 0,
    this.successRate = 0,
    this.avgWakeTime = '--:--',
    this.avgSleepTime = '--:--',
    this.avgWakeRoutine = '--',
    this.avgSleepRoutine = '--',
    this.favoriteMission = '--',
    this.favoriteSound = '--',
    this.heatmap = const [],
    this.progression = const [],
    this.range = InsightsRange.week,
    this.loading = true,
    this.sessions = const [],
    this.totalWakeups = 0,
  });

  InsightsState copyWith({
    int? currentStreak,
    int? longestStreak,
    int? badgesEarned,
    int? totalBadges,
    BadgeModel? currentBadge,
    BadgeModel? nextBadge,
    int? successCount,
    double? successRate,
    String? avgWakeTime,
    String? avgSleepTime,
    String? avgWakeRoutine,
    String? avgSleepRoutine,
    String? favoriteMission,
    String? favoriteSound,
    List<HeatmapDay>? heatmap,
    List<ProgressPoint>? progression,
    InsightsRange? range,
    bool? loading,
    List<WakeupSession>? sessions,
    int? totalWakeups,
  }) =>
      InsightsState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        badgesEarned: badgesEarned ?? this.badgesEarned,
        totalBadges: totalBadges ?? this.totalBadges,
        // currentBadge/nextBadge are nullable and can legitimately be null, so
        // they are always passed explicitly from _recompute rather than merged.
        currentBadge: currentBadge,
        nextBadge: nextBadge,
        successCount: successCount ?? this.successCount,
        successRate: successRate ?? this.successRate,
        avgWakeTime: avgWakeTime ?? this.avgWakeTime,
        avgSleepTime: avgSleepTime ?? this.avgSleepTime,
        avgWakeRoutine: avgWakeRoutine ?? this.avgWakeRoutine,
        avgSleepRoutine: avgSleepRoutine ?? this.avgSleepRoutine,
        favoriteMission: favoriteMission ?? this.favoriteMission,
        favoriteSound: favoriteSound ?? this.favoriteSound,
        heatmap: heatmap ?? this.heatmap,
        progression: progression ?? this.progression,
        range: range ?? this.range,
        loading: loading ?? this.loading,
        sessions: sessions ?? this.sessions,
        totalWakeups: totalWakeups ?? this.totalWakeups,
      );
}
