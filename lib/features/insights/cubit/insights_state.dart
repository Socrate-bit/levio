import '../../wakeup/models/wakeup_session.dart';

enum InsightsRange { week, month, allTime }

class InsightsState {
  final int currentStreak;
  final int longestStreak;
  final List<bool> weekDays;
  final int badgesEarned;
  final int totalBadges;
  final String avgWakeTime;
  final String avgResponseTime;
  final String favoriteMission;
  final String favoriteSound;
  final double consistency; // 0–100
  final InsightsRange range;
  final bool loading;
  final List<WakeupSession> sessions;
  final int totalWakeups;

  const InsightsState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weekDays = const [false, false, false, false, false, false, false],
    this.badgesEarned = 0,
    this.totalBadges = 13,
    this.avgWakeTime = '--:--',
    this.avgResponseTime = '--',
    this.favoriteMission = '--',
    this.favoriteSound = '--',
    this.consistency = 0,
    this.range = InsightsRange.week,
    this.loading = true,
    this.sessions = const [],
    this.totalWakeups = 0,
  });

  InsightsState copyWith({
    int? currentStreak,
    int? longestStreak,
    List<bool>? weekDays,
    int? badgesEarned,
    int? totalBadges,
    String? avgWakeTime,
    String? avgResponseTime,
    String? favoriteMission,
    String? favoriteSound,
    double? consistency,
    InsightsRange? range,
    bool? loading,
    List<WakeupSession>? sessions,
    int? totalWakeups,
  }) =>
      InsightsState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        weekDays: weekDays ?? this.weekDays,
        badgesEarned: badgesEarned ?? this.badgesEarned,
        totalBadges: totalBadges ?? this.totalBadges,
        avgWakeTime: avgWakeTime ?? this.avgWakeTime,
        avgResponseTime: avgResponseTime ?? this.avgResponseTime,
        favoriteMission: favoriteMission ?? this.favoriteMission,
        favoriteSound: favoriteSound ?? this.favoriteSound,
        consistency: consistency ?? this.consistency,
        range: range ?? this.range,
        loading: loading ?? this.loading,
        sessions: sessions ?? this.sessions,
        totalWakeups: totalWakeups ?? this.totalWakeups,
      );
}
