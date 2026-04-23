import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/alarms/services/alarm_firestore_service.dart';
import '../../../features/missions/models/mission.dart';
import '../../subscription/services/analytics_service.dart';
import '../../auth/auth_service.dart';
import '../../../features/wakeup/models/wakeup_session.dart';
import '../../../features/wakeup/services/history_service.dart';
import '../models/badge_model.dart';

/// Per-day status used by the home weekly widget.
enum DayStatus { none, done, frozen }

/// Result of [StreakService.computeStreak].
class StreakResult {
  /// Number of consecutive days (sessions + freezes) walking backward from today.
  final int streak;

  /// Sun..Sat statuses for the current calendar week.
  final List<DayStatus> weekDays;

  const StreakResult({required this.streak, required this.weekDays});
}

class StreakProfile {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWakeupDate;
  final int totalWakeups;
  final List<String> earnedBadgeIds;
  final List<String> usedSoundIds;
  final List<String> usedMissionTypeNames;

  const StreakProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWakeupDate,
    this.totalWakeups = 0,
    this.earnedBadgeIds = const [],
    this.usedSoundIds = const [],
    this.usedMissionTypeNames = const [],
  });

  factory StreakProfile.fromMap(Map<String, dynamic> data) => StreakProfile(
        currentStreak: (data['currentStreak'] as int?) ?? 0,
        longestStreak: (data['longestStreak'] as int?) ?? 0,
        lastWakeupDate: data['lastWakeupDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                data['lastWakeupDate'] as int)
            : null,
        totalWakeups: (data['totalWakeups'] as int?) ?? 0,
        earnedBadgeIds:
            List<String>.from(data['earnedBadgeIds'] as List? ?? []),
        usedSoundIds: List<String>.from(data['usedSoundIds'] as List? ?? []),
        usedMissionTypeNames:
            List<String>.from(data['usedMissionTypeNames'] as List? ?? []),
      );

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastWakeupDate': lastWakeupDate?.millisecondsSinceEpoch,
        'totalWakeups': totalWakeups,
        'earnedBadgeIds': earnedBadgeIds,
        'usedSoundIds': usedSoundIds,
        'usedMissionTypeNames': usedMissionTypeNames,
      };
}

class WakeupResult {
  final int newStreak;
  final List<BadgeModel> newlyEarnedBadges;
  const WakeupResult({required this.newStreak, required this.newlyEarnedBadges});
}

class StreakService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _profileDoc =>
      _db
          .collection('users')
          .doc(AuthService.uid)
          .collection('meta')
          .doc('profile');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Future<StreakProfile> getProfile() async {
    final doc = await _profileDoc.get();
    if (!doc.exists || doc.data() == null) return const StreakProfile();
    return StreakProfile.fromMap(doc.data()!);
  }

  /// Real-time stream of the user's streak profile.
  static Stream<StreakProfile> watchProfile() {
    return _profileDoc.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return const StreakProfile();
      return StreakProfile.fromMap(doc.data()!);
    });
  }

  /// Called when the user successfully dismisses an alarm.
  /// [sessionId] is the Firestore session document ID (already completed).
  static Future<WakeupResult> onWakeupCompleted({
    required String sessionId,
    String? soundId,
    int timeTakenSeconds = 0,
    MissionType? missionType,
  }) async {
    final profile = await getProfile();
    final now = DateTime.now();

    // Already woken up today — no streak update
    if (profile.lastWakeupDate != null &&
        _isSameDay(profile.lastWakeupDate!, now)) {
      return WakeupResult(
          newStreak: profile.currentStreak, newlyEarnedBadges: []);
    }

    // -------------------------------------------------------------------------
    // Streak: walk backward from today; freezes (max 2/week, max 2 in a row)
    // bridge missed days; first session date stops the walk.
    // -------------------------------------------------------------------------
    final newStreak = await computeCurrentStreak();
    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    // -------------------------------------------------------------------------
    // Badge evaluation
    // -------------------------------------------------------------------------
    final allStreakBadges = buildStreakBadges();
    final newlyEarned = <BadgeModel>[];
    final updatedBadgeIds = List<String>.from(profile.earnedBadgeIds);

    // Streak badges
    for (final badge in allStreakBadges) {
      if (!updatedBadgeIds.contains(badge.id) &&
          badge.requiredDays != null &&
          newStreak >= badge.requiredDays!) {
        newlyEarned.add(badge.copyWith(earned: true, earnedDate: now));
        updatedBadgeIds.add(badge.id);
      }
    }

    final achieveBadges = buildAchievementBadges();

    // Blitz: dismissed in under 15s
    if (!updatedBadgeIds.contains('blitz') && timeTakenSeconds < 15 && timeTakenSeconds > 0) {
      final blitz = achieveBadges.firstWhere((b) => b.id == 'blitz');
      newlyEarned.add(blitz.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('blitz');
    }

    // First Light: before 5:30 AM
    if (!updatedBadgeIds.contains('first_light') &&
        (now.hour < 5 || (now.hour == 5 && now.minute < 30))) {
      final fl = achieveBadges.firstWhere((b) => b.id == 'first_light');
      newlyEarned.add(fl.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('first_light');
    }

    // Audiophile: 4+ distinct sounds
    final updatedSounds = List<String>.from(profile.usedSoundIds);
    if (soundId != null && soundId.isNotEmpty && !updatedSounds.contains(soundId)) {
      updatedSounds.add(soundId);
    }
    if (!updatedBadgeIds.contains('audiophile') && updatedSounds.length >= 4) {
      final audio = achieveBadges.firstWhere((b) => b.id == 'audiophile');
      newlyEarned.add(audio.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('audiophile');
    }

    // Converted: first time streak hits 7
    if (!updatedBadgeIds.contains('converted') && newStreak == 7) {
      final conv = achieveBadges.firstWhere((b) => b.id == 'converted');
      newlyEarned.add(conv.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('converted');
    }

    // Versatile: all mission types used
    final updatedMissions = List<String>.from(profile.usedMissionTypeNames);
    if (missionType != null && missionType != MissionType.none &&
        !updatedMissions.contains(missionType.name)) {
      updatedMissions.add(missionType.name);
    }
    if (!updatedBadgeIds.contains('versatile') &&
        updatedMissions.length >=
            MissionType.values.where((t) => t != MissionType.none).length) {
      final vers = achieveBadges.firstWhere((b) => b.id == 'versatile');
      newlyEarned.add(vers.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('versatile');
    }

    // No Days Off: 30 consecutive days
    if (!updatedBadgeIds.contains('no_days_off') && newStreak >= 30) {
      final ndo = achieveBadges.firstWhere((b) => b.id == 'no_days_off');
      newlyEarned.add(ndo.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('no_days_off');
    }

    // -------------------------------------------------------------------------
    // Save to Firestore
    // -------------------------------------------------------------------------
    await _profileDoc.set({
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastWakeupDate': now.millisecondsSinceEpoch,
      'earnedBadgeIds': updatedBadgeIds,
      'usedSoundIds': updatedSounds,
      'usedMissionTypeNames': updatedMissions,
    }, SetOptions(merge: true));

    if (newStreak > profile.currentStreak) {
      AnalyticsService.capture(
        AnalyticsService.streakMilestone,
        {'days': newStreak},
      );
    }
    for (final badge in newlyEarned) {
      AnalyticsService.capture(
        AnalyticsService.badgeEarned,
        {'badge_id': badge.id},
      );
    }

    return WakeupResult(newStreak: newStreak, newlyEarnedBadges: newlyEarned);
  }

  static Future<bool> hasWokenUpToday() async {
    final profile = await getProfile();
    if (profile.lastWakeupDate == null) return false;
    return _isSameDay(profile.lastWakeupDate!, DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Streak computation (single source of truth)
  // ---------------------------------------------------------------------------

  /// Walks backward from today through [sessions], applying freeze rules:
  ///   - At most 2 freezes per Mon–Sun calendar week.
  ///   - At most 2 consecutive freezes in a row.
  /// The walk stops when it would cross before [stopDate]. If [stopDate] is
  /// null, the walk stops at the day of the oldest completed session — so
  /// pre-app-start days never count as misses.
  ///
  /// Returns the streak count and Sun..Sat statuses for the current calendar
  /// week (today displays as `none` when there is no completed session, even
  /// if a freeze was internally applied, because today is in-progress).
  ///
  /// [now] is injectable for testing.
  static StreakResult computeStreak({
    required List<WakeupSession> sessions,
    DateTime? stopDate,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    // Index completed sessions by date; track the oldest.
    final sessionDays = <String>{};
    DateTime? oldestSessionDay;
    for (final s in sessions) {
      if (!s.completed) continue;
      final d = _dateOnly(s.timestamp);
      sessionDays.add(_dateStr(d));
      if (oldestSessionDay == null || d.isBefore(oldestSessionDay)) {
        oldestSessionDay = d;
      }
    }

    // Build the display week (Sun..Sat) with done marks; freezes filled in
    // during the walk below.
    final startOfDisplayWeek = _startOfDisplayWeek(today);
    final endOfDisplayWeek = _addDays(startOfDisplayWeek, 6);
    final weekDays = List<DayStatus>.filled(7, DayStatus.none);
    for (int i = 0; i < 7; i++) {
      final d = _addDays(startOfDisplayWeek, i);
      if (sessionDays.contains(_dateStr(d))) {
        weekDays[i] = DayStatus.done;
      }
    }

    final effectiveStop =
        stopDate != null ? _dateOnly(stopDate) : oldestSessionDay;
    if (effectiveStop == null) {
      return StreakResult(streak: 0, weekDays: weekDays);
    }

    int streak = 0;
    int weekFreezes = 0;
    int consecutiveFreezes = 0;
    DateTime currentMonday = _getMondayOfWeek(today);
    DateTime cursor = today;

    while (!cursor.isBefore(effectiveStop)) {
      // Reset the per-week freeze budget when crossing a Monday backward.
      final cursorMonday = _getMondayOfWeek(cursor);
      if (!_isSameDay(cursorMonday, currentMonday)) {
        weekFreezes = 0;
        currentMonday = cursorMonday;
      }

      if (sessionDays.contains(_dateStr(cursor))) {
        streak++;
        consecutiveFreezes = 0;
      } else if (weekFreezes < 2 && consecutiveFreezes < 2) {
        weekFreezes++;
        consecutiveFreezes++;
        // Mark the display week as frozen for past days only — today stays
        // `none` because it is still in-progress visually.
        if (!_isSameDay(cursor, today) &&
            !cursor.isBefore(startOfDisplayWeek) &&
            !cursor.isAfter(endOfDisplayWeek)) {
          final idx = cursor.difference(startOfDisplayWeek).inDays;
          weekDays[idx] = DayStatus.frozen;
        }
      } else {
        break;
      }

      cursor = _addDays(cursor, -1);
    }

    return StreakResult(streak: streak, weekDays: weekDays);
  }

  /// Backward-compatible wrapper. [firstAlarmDate] is accepted but ignored —
  /// the walk now stops at the oldest session date.
  static Future<int> computeCurrentStreak([
    List<WakeupSession>? sessions,
    DateTime? firstAlarmDate,
  ]) async {
    sessions ??= await HistoryService.getSessions(
      limit: 400,
      includeIncomplete: false,
    );
    return computeStreak(sessions: sessions).streak;
  }

  /// Returns the earliest createdAt date across all alarms, or null if none.
  static Future<DateTime?> getFirstAlarmCreatedDate() async {
    final alarms = await AlarmFirestoreService.getAlarms();
    if (alarms.isEmpty) return null;
    alarms.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return alarms.first.createdAt;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the Monday of the ISO week containing [date].
  static DateTime _getMondayOfWeek(DateTime date) {
    // weekday: Mon=1 … Sun=7
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Returns the Sunday that begins the display week containing [date].
  static DateTime _startOfDisplayWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7; // Sun=7→0
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
