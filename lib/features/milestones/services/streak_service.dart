import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/alarms/services/alarm_firestore_service.dart';
import '../../../features/missions/models/mission.dart';
import '../../../services/auth_service.dart';
import '../../../features/wakeup/models/wakeup_session.dart';
import '../../../features/wakeup/services/history_service.dart';
import '../models/badge_model.dart';

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
    // Streak: count completed sessions walking backward, tolerance = 2 misses/week (Mon–Sun)
    // -------------------------------------------------------------------------
    final newStreak = await _computeCurrentStreak();
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

    return WakeupResult(newStreak: newStreak, newlyEarnedBadges: newlyEarned);
  }

  static Future<bool> hasWokenUpToday() async {
    final profile = await getProfile();
    if (profile.lastWakeupDate == null) return false;
    return _isSameDay(profile.lastWakeupDate!, DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Streak computation
  // ---------------------------------------------------------------------------

  /// Computes current streak by walking backward through days from today.
  /// Each day without a completed session is a "miss". The week (Mon–Sun)
  /// tolerates up to 2 misses. Exceeding the tolerance breaks the streak.
  /// Days before [firstAlarmDate] are ignored (user hadn't started yet).
  ///
  /// Pass [sessions] to avoid an extra Firestore fetch; omit to fetch internally.
  static Future<int> computeCurrentStreak([
    List<WakeupSession>? sessions,
    DateTime? firstAlarmDate,
  ]) async {
    return _computeCurrentStreak(sessions, firstAlarmDate);
  }

  static Future<int> _computeCurrentStreak([
    List<WakeupSession>? sessions,
    DateTime? firstAlarmDate,
  ]) async {
    // Fetch completed sessions for the last year (enough for any streak)
    sessions ??= await HistoryService.getSessions(
      limit: 400,
      includeIncomplete: false,
    );

    if (sessions.isEmpty) return 0;

    // If no firstAlarmDate provided, fetch from Firestore
    firstAlarmDate ??= await _getFirstAlarmCreatedDate();

    // Build a set of 'yyyy-MM-dd' strings with at least one completed session
    final completedDates = <String>{};
    for (final s in sessions) {
      completedDates.add(_dateStr(s.timestamp));
    }

    final today = DateTime.now();
    int streak = 0;
    int weekMisses = 0;
    DateTime? currentWeekMonday;

    // Start from yesterday — today is still in progress and shouldn't count as a miss
    // (but if today has a session, count it)
    final hasSessionToday = completedDates.contains(_dateStr(today));
    if (hasSessionToday) streak++;

    for (int i = 1; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));

      // Stop before the first alarm was created — no misses before that
      if (firstAlarmDate != null && day.isBefore(
        DateTime(firstAlarmDate.year, firstAlarmDate.month, firstAlarmDate.day),
      )) {
        break;
      }

      final weekMonday = _getMondayOfWeek(day);

      if (currentWeekMonday == null) {
        currentWeekMonday = weekMonday;
      } else if (!_isSameDay(weekMonday, currentWeekMonday)) {
        // Entered a new (earlier) week — reset miss counter
        weekMisses = 0;
        currentWeekMonday = weekMonday;
      }

      if (completedDates.contains(_dateStr(day))) {
        streak++;
      } else {
        weekMisses++;
        if (weekMisses > 2) break;
      }
    }

    return streak;
  }

  /// Returns the earliest createdAt date across all alarms, or null if none.
  static Future<DateTime?> _getFirstAlarmCreatedDate() async {
    final alarms = await AlarmFirestoreService.getAlarms();
    if (alarms.isEmpty) return null;
    alarms.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return alarms.first.createdAt;
  }

  /// Public accessor for the first alarm creation date.
  static Future<DateTime?> getFirstAlarmCreatedDate() => _getFirstAlarmCreatedDate();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns the Monday of the week containing [date].
  static DateTime _getMondayOfWeek(DateTime date) {
    // weekday: Mon=1 … Sun=7
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
