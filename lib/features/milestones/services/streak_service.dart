import 'package:cloud_firestore/cloud_firestore.dart';

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

  const StreakProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWakeupDate,
    this.totalWakeups = 0,
    this.freezesUsedThisWeek = 0,
    this.earnedBadgeIds = const [],
    this.usedSoundIds = const [],
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
      );

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastWakeupDate': lastWakeupDate?.millisecondsSinceEpoch,
        'totalWakeups': totalWakeups,
        'freezesUsedThisWeek': freezesUsedThisWeek,
        'earnedBadgeIds': earnedBadgeIds,
        'usedSoundIds': usedSoundIds,
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
      _db.collection('users').doc(AuthService.uid).collection('meta').doc('profile');

  static Future<StreakProfile> getProfile() async {
    final doc = await _profileDoc.get();
    if (!doc.exists || doc.data() == null) return const StreakProfile();
    return StreakProfile.fromMap(doc.data()!);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isYesterday(DateTime date, DateTime reference) {
    final yesterday = reference.subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  /// Called when the user successfully dismisses an alarm.
  /// Returns newly earned badges.
  static Future<WakeupResult> onWakeupCompleted({
    String? soundId,
    int timeTakenSeconds = 0,
  }) async {
    final profile = await getProfile();
    final now = DateTime.now();

    // Already woken up today — no streak update needed
    if (profile.lastWakeupDate != null &&
        _isSameDay(profile.lastWakeupDate!, now)) {
      return WakeupResult(
          newStreak: profile.currentStreak, newlyEarnedBadges: []);
    }

    int newStreak = profile.currentStreak;

    if (profile.lastWakeupDate == null) {
      newStreak = 1;
    } else if (_isYesterday(profile.lastWakeupDate!, now)) {
      newStreak = profile.currentStreak + 1;
    } else {
      // Missed day(s) — apply freeze or reduce streak
      final daysMissed = now
          .difference(profile.lastWakeupDate!)
          .inDays - 1;
      final freezesAvailable = 2 - profile.freezesUsedThisWeek;
      if (daysMissed <= freezesAvailable) {
        // Use freeze days
        newStreak = profile.currentStreak + 1;
      } else {
        // Streak drops by 3 per missed unfrozen day, not reset to 0
        newStreak = (profile.currentStreak - (daysMissed * 3)).clamp(0, 9999);
      }
    }

    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    // Check for newly earned streak badges
    final allStreakBadges = buildStreakBadges();
    final newlyEarned = <BadgeModel>[];
    final updatedBadgeIds = List<String>.from(profile.earnedBadgeIds);

    for (final badge in allStreakBadges) {
      if (!updatedBadgeIds.contains(badge.id) &&
          badge.requiredDays != null &&
          newStreak >= badge.requiredDays!) {
        newlyEarned.add(badge.copyWith(earned: true, earnedDate: now));
        updatedBadgeIds.add(badge.id);
      }
    }

    // Achievement badges
    final achieveBadges = buildAchievementBadges();

    // Blitz: dismissed in under 15s
    if (!updatedBadgeIds.contains('blitz') && timeTakenSeconds < 15) {
      final blitz = achieveBadges.firstWhere((b) => b.id == 'blitz');
      newlyEarned.add(blitz.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('blitz');
    }

    // First Light: before 5:30 AM
    if (!updatedBadgeIds.contains('first_light') &&
        now.hour < 5 ||
        (now.hour == 5 && now.minute < 30)) {
      if (!updatedBadgeIds.contains('first_light')) {
        final fl = achieveBadges.firstWhere((b) => b.id == 'first_light');
        newlyEarned.add(fl.copyWith(earned: true, earnedDate: now));
        updatedBadgeIds.add('first_light');
      }
    }

    // Update sound tracking for Audiophile badge
    final updatedSounds = List<String>.from(profile.usedSoundIds);
    if (soundId != null && !updatedSounds.contains(soundId)) {
      updatedSounds.add(soundId);
    }
    if (!updatedBadgeIds.contains('audiophile') && updatedSounds.length >= 4) {
      final audio = achieveBadges.firstWhere((b) => b.id == 'audiophile');
      newlyEarned.add(audio.copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add('audiophile');
    }

    // Save to Firestore
    await _profileDoc.set({
      'currentStreak': newStreak,
      'longestStreak': newLongest,
      'lastWakeupDate': now.millisecondsSinceEpoch,
      'totalWakeups': FieldValue.increment(1),
      'earnedBadgeIds': updatedBadgeIds,
      'usedSoundIds': updatedSounds,
    }, SetOptions(merge: true));

    return WakeupResult(newStreak: newStreak, newlyEarnedBadges: newlyEarned);
  }

  static Future<bool> hasWokenUpToday() async {
    final profile = await getProfile();
    if (profile.lastWakeupDate == null) return false;
    return _isSameDay(profile.lastWakeupDate!, DateTime.now());
  }
}
