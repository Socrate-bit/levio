import 'package:flutter_test/flutter_test.dart';
import 'package:levio/features/milestones/services/streak_service.dart';
import 'package:levio/features/wakeup/models/wakeup_session.dart';

/// Builds a [WakeupSession] anchored to [day] (treated as midnight).
WakeupSession _session(DateTime day) => WakeupSession(
      id: 'session-${day.toIso8601String()}',
      timestamp: DateTime(day.year, day.month, day.day, 7, 0),
      timeTakenSeconds: 30,
    );

/// Translates a left=oldest, right=newest pattern string into a session list.
/// `S` → completed session, anything else → no session.
List<WakeupSession> _sessionsFromPattern(String pattern, DateTime today) {
  final sessions = <WakeupSession>[];
  for (int i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    final daysAgo = pattern.length - 1 - i; // rightmost = today
    final day = DateTime(today.year, today.month, today.day - daysAgo);
    if (char == 'S') sessions.add(_session(day));
  }
  return sessions;
}

void main() {
  // Anchor "today" at Thursday 2026-04-23 so the patterns straddle the
  // Mon–Sun week boundary in a realistic way.
  final today = DateTime(2026, 4, 23);

  group('StreakService.computeStreak — canonical examples', () {
    test('MMMSMMM → 0 (today missed, 2 freezes used, 3rd miss breaks)', () {
      final sessions = _sessionsFromPattern('MMMSMMM', today);
      expect(
        StreakService.computeStreak(sessions: sessions, now: today).streak,
        0,
      );
    });

    test('SSSSSFF → 5 (2 trailing freezes, 5 sessions back to first)', () {
      final sessions = _sessionsFromPattern('SSSSSFF', today);
      expect(
        StreakService.computeStreak(sessions: sessions, now: today).streak,
        5,
      );
    });

    test('SSSFSSS → 6 (single mid-week freeze bridges the gap)', () {
      final sessions = _sessionsFromPattern('SSSFSSS', today);
      expect(
        StreakService.computeStreak(sessions: sessions, now: today).streak,
        6,
      );
    });

    test('SSFFSSS → 5 (two consecutive freezes bridge the gap)', () {
      final sessions = _sessionsFromPattern('SSFFSSS', today);
      expect(
        StreakService.computeStreak(sessions: sessions, now: today).streak,
        5,
      );
    });

    test('SFSSSSF → 5 (freezes split across week boundary, both within budget)',
        () {
      final sessions = _sessionsFromPattern('SFSSSSF', today);
      expect(
        StreakService.computeStreak(sessions: sessions, now: today).streak,
        5,
      );
    });

    test('MMMSSD → 2 (today has no alarm, 2 sessions before 3-miss break)', () {
      // D in the user's notation = today with no completed session. Same
      // result as `MMMSSM` because today is treated as a miss for the walk
      // but is invisible in the display.
      final sessions = _sessionsFromPattern('MMMSSM', today);
      expect(
        StreakService.computeStreak(sessions: sessions, now: today).streak,
        2,
      );
    });
  });

  group('StreakService.computeStreak — edge cases', () {
    test('empty sessions → 0 streak, all weekDays none', () {
      final result =
          StreakService.computeStreak(sessions: const [], now: today);
      expect(result.streak, 0);
      expect(result.weekDays, List.filled(7, DayStatus.none));
    });

    test('only today has a session → streak 1, today shows done', () {
      final sessions = [_session(today)];
      final result =
          StreakService.computeStreak(sessions: sessions, now: today);
      expect(result.streak, 1);
      // 2026-04-23 is Thursday → index 4 in Sun..Sat.
      expect(result.weekDays[4], DayStatus.done);
      expect(
        result.weekDays.where((s) => s == DayStatus.done).length,
        1,
      );
    });

    test('today display stays none even when freeze applied internally', () {
      // SSSSSFF: today has no session, but internally consumes a freeze.
      // The Sun..Sat display for today must remain `none` (in-progress).
      final sessions = _sessionsFromPattern('SSSSSFF', today);
      final result =
          StreakService.computeStreak(sessions: sessions, now: today);
      // Thursday index = 4
      expect(result.weekDays[4], DayStatus.none);
    });

    test('incomplete sessions are ignored', () {
      final incomplete = WakeupSession(
        id: 'incomplete',
        timestamp: today,
        timeTakenSeconds: 0,
        completed: false,
      );
      final result = StreakService.computeStreak(
        sessions: [incomplete],
        now: today,
      );
      expect(result.streak, 0);
    });

    test('stopDate override halts walk before exhausting freezes', () {
      // 7 days of misses ending today, with one ancient session anchoring the
      // walk. Without override the walk goes back to that session; with
      // override at yesterday, it stops sooner.
      final ancient = _session(DateTime(today.year, today.month, today.day - 30));
      final result = StreakService.computeStreak(
        sessions: [ancient],
        stopDate: DateTime(today.year, today.month, today.day - 1),
        now: today,
      );
      expect(result.streak, 0);
    });
  });
}
