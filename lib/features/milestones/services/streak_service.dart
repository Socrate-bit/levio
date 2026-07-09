import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/alarms/services/alarm_firestore_service.dart';
import '../../../features/missions/models/mission.dart';
import '../../subscription/services/analytics_service.dart';
import '../../auth/auth_service.dart';
import '../../../features/wakeup/models/wakeup_session.dart';
import '../../../features/wakeup/services/history_service.dart';
import '../models/badge_model.dart';

/// Per-day status used by the home weekly widget.
enum DayStatus { none, done, frozen, missed }

/// Result of [StreakService.computeStreak].
class StreakResult {
  /// Number of consecutive validated days in the live streak ending today.
  final int streak;

  /// Sun..Sat statuses for the current calendar week.
  final List<DayStatus> weekDays;

  /// Date strings (yyyy-MM-dd) of every day resolved to a freeze, across the
  /// full history — used by the insights activity heatmap. Today is excluded
  /// (it is in-progress and never shown as frozen).
  final Set<String> frozenDays;

  /// Raw per-day model status (done/frozen/missed) for every day in the walked
  /// range, today included. Unlike [frozenDays]/[weekDays] this is not filtered
  /// for display — it exposes the full labeling for tests and callers that want
  /// each day's true status.
  final Map<String, DayStatus> dayStatuses;

  const StreakResult({
    required this.streak,
    required this.weekDays,
    this.frozenDays = const {},
    this.dayStatuses = const {},
  });
}

class StreakProfile {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWakeupDate;
  final int totalWakeups;
  final List<String> earnedBadgeIds;
  final List<String> usedSoundIds;
  // Mission types completed on wake-up alarms (drives the wake "Versatile" badge).
  final List<String> usedMissionTypeNames;
  // Mission types completed on sleep alarms (drives the sleep "Dreamer" badge).
  final List<String> usedSleepMissionTypeNames;

  const StreakProfile({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWakeupDate,
    this.totalWakeups = 0,
    this.earnedBadgeIds = const [],
    this.usedSoundIds = const [],
    this.usedMissionTypeNames = const [],
    this.usedSleepMissionTypeNames = const [],
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
        usedSleepMissionTypeNames: List<String>.from(
            data['usedSleepMissionTypeNames'] as List? ?? []),
      );

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastWakeupDate': lastWakeupDate?.millisecondsSinceEpoch,
        'totalWakeups': totalWakeups,
        'earnedBadgeIds': earnedBadgeIds,
        'usedSoundIds': usedSoundIds,
        'usedMissionTypeNames': usedMissionTypeNames,
        'usedSleepMissionTypeNames': usedSleepMissionTypeNames,
      };
}

/// Mission types that count toward the sleep "Dreamer" badge (all 6 wind-down
/// missions).
const _sleepMissionTypes = <MissionType>[
  MissionType.breathing,
  MissionType.meditation,
  MissionType.gratefulness,
  MissionType.routine,
  MissionType.bedPhoto,
  MissionType.affirmation,
];

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
    bool isSleep = false,
  }) async {
    final profile = await getProfile();
    final now = DateTime.now();

    // Streak advances at most once per day, but later same-day completions must
    // still be evaluated for badges — e.g. a sleep alarm the same evening as the
    // morning wake-up shares the calendar day yet should still award sleep badges.
    final alreadyToday = profile.lastWakeupDate != null &&
        _isSameDay(profile.lastWakeupDate!, now);

    // -------------------------------------------------------------------------
    // Streak: walk backward from today; freezes (max 2/week, max 2 in a row)
    // bridge missed days; first session date stops the walk.
    // -------------------------------------------------------------------------
    final newStreak =
        alreadyToday ? profile.currentStreak : await computeCurrentStreak();
    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    // -------------------------------------------------------------------------
    // Badge evaluation
    // -------------------------------------------------------------------------
    final allStreakBadges = buildStreakBadges();
    final newlyEarned = <BadgeModel>[];
    final updatedBadgeIds = List<String>.from(profile.earnedBadgeIds);

    // Streak badges (shared across wake-up and sleep alarms).
    for (final badge in allStreakBadges) {
      if (!updatedBadgeIds.contains(badge.id) &&
          badge.requiredDays != null &&
          newStreak >= badge.requiredDays!) {
        newlyEarned.add(badge.copyWith(earned: true, earnedDate: now));
        updatedBadgeIds.add(badge.id);
      }
    }

    // Variety trackers accrue per alarm type so wake badges derive purely from
    // wake-up alarms and sleep badges purely from sleep alarms.
    final updatedSounds = List<String>.from(profile.usedSoundIds);
    final updatedMissions = List<String>.from(profile.usedMissionTypeNames);
    final updatedSleepMissions =
        List<String>.from(profile.usedSleepMissionTypeNames);

    void earn(List<BadgeModel> pool, String id) {
      if (updatedBadgeIds.contains(id)) return;
      newlyEarned.add(
          pool.firstWhere((b) => b.id == id).copyWith(earned: true, earnedDate: now));
      updatedBadgeIds.add(id);
    }

    // -------------------------------------------------------------------------
    // Achievement badges — gated by alarm type so each set only ever unlocks on
    // its matching alarm. Sleep alarms never award wake-up badges and vice versa.
    // -------------------------------------------------------------------------
    if (isSleep) {
      final sleepBadges = buildSleepAchievementBadges();

      // First Night: first completed sleep alarm.
      earn(sleepBadges, 'first_night');

      // Early to Bed: wind down in the evening, before 10 PM (excludes
      // after-midnight completions, which are the opposite of "early").
      if (now.hour >= 18 && now.hour < 22) earn(sleepBadges, 'early_to_bed');

      // Calm Mind: a meditation or breathing wind-down.
      if (missionType == MissionType.meditation ||
          missionType == MissionType.breathing) {
        earn(sleepBadges, 'calm_mind');
      }

      // Dreamer: all wind-down mission types used on sleep alarms.
      if (missionType != null &&
          missionType != MissionType.none &&
          !updatedSleepMissions.contains(missionType.name)) {
        updatedSleepMissions.add(missionType.name);
      }
      if (_sleepMissionTypes.every((t) => updatedSleepMissions.contains(t.name))) {
        earn(sleepBadges, 'dreamer');
      }

      // Well Rested: a 7-day streak reached via a sleep alarm.
      if (newStreak >= 7) earn(sleepBadges, 'well_rested');

      // No Nights Off: 30 consecutive nights.
      if (newStreak >= 30) earn(sleepBadges, 'no_nights_off');
    } else {
      final achieveBadges = buildAchievementBadges();

      // Blitz: dismissed in under 15s.
      if (timeTakenSeconds < 15 && timeTakenSeconds > 0) {
        earn(achieveBadges, 'blitz');
      }

      // First Light: before 5:30 AM.
      if (now.hour < 5 || (now.hour == 5 && now.minute < 30)) {
        earn(achieveBadges, 'first_light');
      }

      // Audiophile: 4+ distinct sounds on wake-up alarms.
      if (soundId != null &&
          soundId.isNotEmpty &&
          !updatedSounds.contains(soundId)) {
        updatedSounds.add(soundId);
      }
      if (updatedSounds.length >= 4) earn(achieveBadges, 'audiophile');

      // Converted: streak of 7 reached via a wake-up alarm.
      if (newStreak >= 7) earn(achieveBadges, 'converted');

      // Versatile: all mission types used on wake-up alarms.
      if (missionType != null &&
          missionType != MissionType.none &&
          !updatedMissions.contains(missionType.name)) {
        updatedMissions.add(missionType.name);
      }
      if (updatedMissions.length >=
          MissionType.values.where((t) => t != MissionType.none).length) {
        earn(achieveBadges, 'versatile');
      }

      // No Days Off: 30 consecutive days.
      if (newStreak >= 30) earn(achieveBadges, 'no_days_off');
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
      'usedSleepMissionTypeNames': updatedSleepMissions,
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

  /// Labels every day from the oldest completed session (or [stopDate]) up to
  /// today with a [DayStatus], applying the freeze rules:
  ///   - A day is `done` if it has ≥1 completed, non-screen-time-disabled session.
  ///   - An unvalidated day may `freeze` only if the previous day was done or
  ///     frozen, at most 2 freezes per Mon–Sun week, and at most 2 consecutive.
  ///   - Freezes inside a gap between two validated days are kept even when the
  ///     gap doesn't fully bridge (historical record). A dead tail — the run
  ///     after the last validated day that fails to reach today alive — reverts
  ///     its freezes to `missed`, so a broken current streak shows clean misses.
  ///
  /// The current [streak] is the run of consecutive validated days ending in the
  /// live segment that reaches today. Today displays as `none` (in-progress)
  /// even when it is internally frozen or missed.
  ///
  /// [now] is injectable for testing.
  static StreakResult computeStreak({
    required List<WakeupSession> sessions,
    DateTime? stopDate,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    // Index completed sessions by date; track the oldest and the newest. Also
    // track days that had any session at all, so days with only an incomplete
    // (missed) session can be distinguished from days with no alarm.
    final sessionDays = <String>{};
    final anySessionDays = <String>{};
    final disabledDays = <String>{};
    final validatedDates = <DateTime>[];
    DateTime? oldestSessionDay;
    for (final s in sessions) {
      final d = _dateOnly(s.timestamp);
      anySessionDays.add(_dateStr(d));
      if (s.screenTimeDisabled) disabledDays.add(_dateStr(d));
      if (!s.completed) continue;
      sessionDays.add(_dateStr(d));
      validatedDates.add(d);
      if (oldestSessionDay == null || d.isBefore(oldestSessionDay)) {
        oldestSessionDay = d;
      }
    }

    // Deactivating screen-time blocking forces its day to count as missed: drop
    // it from the completed set even if a wake-up also happened that day, so the
    // walk treats it as a (freezable) miss.
    sessionDays.removeAll(disabledDays);

    // Newest day still counting as validated after the screen-time removal.
    // Used to tell a middle gap (validated day still ahead) from a dead tail.
    DateTime? lastValidatedDay;
    for (final d in validatedDates) {
      if (sessionDays.contains(_dateStr(d)) &&
          (lastValidatedDay == null || d.isAfter(lastValidatedDay))) {
        lastValidatedDay = d;
      }
    }

    final startOfDisplayWeek = _startOfDisplayWeek(today);
    final weekDays = List<DayStatus>.filled(7, DayStatus.none);

    final effectiveStop =
        stopDate != null ? _dateOnly(stopDate) : oldestSessionDay;
    if (effectiveStop == null) {
      return StreakResult(streak: 0, weekDays: weekDays);
    }

    // Forward pass from the oldest day to today, labeling each day. `pending`
    // holds the freezes applied since the last validated day (or last break);
    // they are committed on a validated day / middle break, or reverted on a
    // dead tail.
    final dayStatuses = <String, DayStatus>{};
    final pending = <String>[];
    int streak = 0; // validated days in the current (un-broken) run
    int weekFreezes = 0;
    int consecutiveFreezes = 0;
    bool prevGood = false; // previous day was done or frozen
    DateTime currentMonday = _getMondayOfWeek(effectiveStop);

    for (DateTime cursor = effectiveStop;
        !cursor.isAfter(today);
        cursor = _addDays(cursor, 1)) {
      // Reset the per-week freeze budget on each Mon–Sun boundary. The
      // consecutive-freeze cap intentionally persists across weeks.
      final cursorMonday = _getMondayOfWeek(cursor);
      if (!_isSameDay(cursorMonday, currentMonday)) {
        weekFreezes = 0;
        currentMonday = cursorMonday;
      }

      final key = _dateStr(cursor);

      if (sessionDays.contains(key)) {
        dayStatuses[key] = DayStatus.done;
        pending.clear(); // these freezes bridged to a validated day — keep them
        streak++;
        consecutiveFreezes = 0;
        prevGood = true;
      } else if (prevGood && weekFreezes < 2 && consecutiveFreezes < 2) {
        dayStatuses[key] = DayStatus.frozen; // tentative until the run resolves
        pending.add(key);
        weekFreezes++;
        consecutiveFreezes++;
        prevGood = true;
      } else {
        // Break: this day is missed. If a validated day exists later, the freezes
        // in `pending` are a real (middle) bridge attempt — keep them frozen.
        // Otherwise the run is a dead tail — revert its freezes to missed.
        dayStatuses[key] = DayStatus.missed;
        final hasFutureValidated =
            lastValidatedDay != null && lastValidatedDay.isAfter(cursor);
        if (!hasFutureValidated) {
          for (final p in pending) {
            dayStatuses[p] = DayStatus.missed;
          }
        }
        pending.clear();
        streak = 0;
        consecutiveFreezes = 0;
        prevGood = false;
      }
    }

    // Build the display week (Sun..Sat) and the frozen-day set from the resolved
    // statuses. Today always renders `none` (in-progress) and is excluded from
    // the frozen set; days with no alarm/session stay `none` rather than missed.
    final frozenDays = <String>{};
    for (final entry in dayStatuses.entries) {
      if (entry.value == DayStatus.frozen && entry.key != _dateStr(today)) {
        frozenDays.add(entry.key);
      }
    }
    for (int i = 0; i < 7; i++) {
      final d = _addDays(startOfDisplayWeek, i);
      if (d.isAfter(today)) continue; // future stays `none`
      final status = dayStatuses[_dateStr(d)];
      if (_isSameDay(d, today)) {
        // Today is in-progress: only a completed session shows; an internal
        // freeze or miss renders as `none`.
        if (status == DayStatus.done) weekDays[i] = DayStatus.done;
      } else if (status == DayStatus.done || status == DayStatus.frozen) {
        weekDays[i] = status!;
      } else if (status == DayStatus.missed &&
          anySessionDays.contains(_dateStr(d))) {
        // Only show a miss where an alarm actually fired that day.
        weekDays[i] = DayStatus.missed;
      }
    }

    return StreakResult(
      streak: streak,
      weekDays: weekDays,
      frozenDays: frozenDays,
      dayStatuses: dayStatuses,
    );
  }

  /// Backward-compatible wrapper. [firstAlarmDate] is accepted but ignored —
  /// the walk now stops at the oldest session date.
  static Future<int> computeCurrentStreak([
    List<WakeupSession>? sessions,
    DateTime? firstAlarmDate,
  ]) async {
    sessions ??= await HistoryService.getSessions(
      limit: 400,
      includeIncomplete: true, // needed so screen-time-disabled days are misses
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
