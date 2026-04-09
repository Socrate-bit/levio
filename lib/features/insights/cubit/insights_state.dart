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
  final bool loading;

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
    this.loading = true,
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
    bool? loading,
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
        loading: loading ?? this.loading,
      );
}
