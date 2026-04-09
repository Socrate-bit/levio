import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/missions/models/mission.dart';
import '../../../services/auth_service.dart';
import '../models/badge_model.dart';

class StreakProfile {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWakeupDate;
  final int totalWakeups;
  final int freezesUsedThisWeek;
  final List<String> earnedBadgeIds;
  final List<String> usedSoundIds;
  // 'yyyy-MM-dd' strings of days an alarm actually fired (used for rest-day detection)
  final List<String> alarmFiredDates;
  // mission type names the user has used, for Versatile badge
  final List<String> usedMissionTypeNames;

  const StreakProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWakeupDate,
    this.totalWakeups = 0,
    this.freezesUsedThisWeek = 0,
    this.earnedBadgeIds = const [],
    this.usedSoundIds = const [],
    this.alarmFiredDates = const [],
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
        freezesUsedThisWeek: (data['freezesUsedThisWeek'] as int?) ?? 0,
        earnedBadgeIds:
            List<String>.from(data['earnedBadgeIds'] as List? ?? []),
        usedSoundIds: List<String>.from(data['usedSoundIds'] as List? ?? []),
        alarmFiredDates:
            List<String>.from(data['alarmFiredDates'] as List? ?? []),
        usedMissionTypeNames:
            List<String>.from(data['usedMissionTypeNames'] as List? ?? []),
      );

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastWakeupDate': lastWakeupDate?.millisecondsSinceEpoch,
        'totalWakeups': totalWakeups,
        'freezesUsedThisWeek': freezesUsedThisWeek,
        'earnedBadgeIds': earnedBadgeIds,
        'usedSoundIds': usedSoundIds,
        'alarmFiredDates': alarmFiredDates,
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

  /// Call this when an alarm fires (before user completes mission) so we can
  /// distinguish missed alarm days from rest days.
  static Future<void> recordAlarmFired() async {
    final today = _dateStr(DateTime.now());
    await _profileDoc.set(
      {'alarmFiredDates': FieldValue.arrayUnion([today])},
      SetOptions(merge: true),
    );
  }

  /// Called when the user successfully dismisses an alarm.
  static Future<WakeupResult> onWakeupCompleted({
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
    // Freeze week reset: if last wakeup was in a previous calendar week → reset
    // -------------------------------------------------------------------------
    int freezesUsed = profile.freezesUsedThisWeek;
    if (profile.lastWakeupDate != null) {
      final lastSunday = _startOfWeek(profile.lastWakeupDate!);
      final thisSunday = _startOfWeek(now);
      if (!_isSameDay(lastSunday, thisSunday)) {
        freezesUsed = 0;
      }
    }

    // -------------------------------------------------------------------------
    // Streak calculation
    // -------------------------------------------------------------------------
    int newStreak = profile.currentStreak;

    if (profile.lastWakeupDate == null) {
      newStreak = 1;
    } else if (_isYesterday(profile.lastWakeupDate!, now)) {
      newStreak = profile.currentStreak + 1;
    } else {
      // Gap of 2+ days — determine how many were alarm days vs rest days
      final daysSinceLast =
          now.difference(profile.lastWakeupDate!).inDays;
      int missedAlarmDays = 0;
      for (int i = 1; i < daysSinceLast; i++) {
        final date =
            _dateStr(profile.lastWakeupDate!.add(Duration(days: i)));
        if (profile.alarmFiredDates.contains(date)) {
          missedAlarmDays++;
        }
      }

      if (missedAlarmDays == 0) {
        // All gap days were rest days → streak continues
        newStreak = profile.currentStreak + 1;
      } else {
        final freezesAvailable = 2 - freezesUsed;
        if (missedAlarmDays <= freezesAvailable) {
          // Use freeze days — streak continues
          freezesUsed += missedAlarmDays;
          newStreak = profile.currentStreak + 1;
        } else {
          // Missed an alarm day with no freeze → reset streak to 0
          newStreak = 0;
          freezesUsed = 0;
        }
      }
    }

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

    // Blitz: dismissed in under 15s (one-time)
    if (!updatedBadgeIds.contains('blitz') && timeTakenSeconds < 15 && timeTakenSeconds > 0) {
      final blitz = achieveBadges.firstWhere((b) => b.id == 'blitz');
      newlyEarned.add(blitz.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('blitz');
    }

    // First Light: before 5:30 AM (one-time)
    if (!updatedBadgeIds.contains('first_light') &&
        (now.hour < 5 || (now.hour == 5 && now.minute < 30))) {
      final fl = achieveBadges.firstWhere((b) => b.id == 'first_light');
      newlyEarned.add(fl.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('first_light');
    }

    // Audiophile: 4+ distinct sounds across all sessions (one-time)
    final updatedSounds = List<String>.from(profile.usedSoundIds);
    if (soundId != null && soundId.isNotEmpty && !updatedSounds.contains(soundId)) {
      updatedSounds.add(soundId);
    }
    if (!updatedBadgeIds.contains('audiophile') && updatedSounds.length >= 4) {
      final audio = achieveBadges.firstWhere((b) => b.id == 'audiophile');
      newlyEarned.add(audio.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('audiophile');
    }

    // Converted: first time the streak reaches 7 (one-time)
    if (!updatedBadgeIds.contains('converted') && newStreak == 7) {
      final conv = achieveBadges.firstWhere((b) => b.id == 'converted');
      newlyEarned.add(conv.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('converted');
    }

    // Versatile: all 13 mission types used (one-time)
    final updatedMissions = List<String>.from(profile.usedMissionTypeNames);
    if (missionType != null && !updatedMissions.contains(missionType.name)) {
      updatedMissions.add(missionType.name);
    }
    if (!updatedBadgeIds.contains('versatile') &&
        updatedMissions.length >= MissionType.values.length) {
      final vers = achieveBadges.firstWhere((b) => b.id == 'versatile');
      newlyEarned.add(vers.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('versatile');
    }

    // No Days Off: 30 consecutive days (one-time)
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
      'totalWakeups': FieldValue.increment(1),
      'freezesUsedThisWeek': freezesUsed,
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
  // Private helpers
  // ---------------------------------------------------------------------------

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isYesterday(DateTime date, DateTime reference) {
    final yesterday = reference.subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  /// Returns the Sunday of the week containing [date].
  static DateTime _startOfWeek(DateTime date) {
    final daysFromSunday = date.weekday % 7; // Sunday=0 in this scheme
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
