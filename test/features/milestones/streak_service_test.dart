import 'package:flutter_test/flutter_test.dart';
import 'package:levio/features/milestones/services/streak_service.dart';
import 'package:levio/features/wakeup/models/wakeup_session.dart';

/// Builds a completed [WakeupSession] anchored to [day] (validated day).
WakeupSession _session(DateTime day) => WakeupSession(
      id: 'session-${day.toIso8601String()}',
      timestamp: DateTime(day.year, day.month, day.day, 7, 0),
      timeTakenSeconds: 30,
    );

/// Builds a screen-time-disabled session for [day]. It is incomplete and
/// un-validates the day, turning it into a (freezable) miss even if a wake-up
/// also happened.
WakeupSession _screenTimeDisabled(DateTime day) => WakeupSession(
      id: 'stx-${day.toIso8601String()}',
      timestamp: DateTime(day.year, day.month, day.day, 7, 0),
      timeTakenSeconds: 0,
      completed: false,
      screenTimeDisabled: true,
    );

/// Translates a left=oldest, right=newest pattern into a session list.
///   `S` → completed (validated) session
///   `X` → screen-time-disabled session (un-validates the day)
///   anything else → no session (unvalidated day)
List<WakeupSession> _sessionsFromPattern(String pattern, DateTime today) {
  final sessions = <WakeupSession>[];
  for (int i = 0; i < pattern.length; i++) {
    final daysAgo = pattern.length - 1 - i; // rightmost = today
    final day = DateTime(today.year, today.month, today.day - daysAgo);
    switch (pattern[i]) {
      case 'S':
        sessions.add(_session(day));
      case 'X':
        sessions.add(_screenTimeDisabled(day));
    }
  }
  return sessions;
}

/// The oldest day covered by [pattern] (its leftmost character).
DateTime _patternStart(String pattern, DateTime today) =>
    DateTime(today.year, today.month, today.day - (pattern.length - 1));

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Reconstructs the per-day model status across [pattern]'s days from the raw
/// [StreakResult.dayStatuses]: `S` done, `F` frozen, `M` missed, `.` none.
String _statusString(StreakResult r, String pattern, DateTime today) {
  final sb = StringBuffer();
  for (int i = 0; i < pattern.length; i++) {
    final daysAgo = pattern.length - 1 - i;
    final day = DateTime(today.year, today.month, today.day - daysAgo);
    switch (r.dayStatuses[_key(day)]) {
      case DayStatus.done:
        sb.write('S');
      case DayStatus.frozen:
        sb.write('F');
      case DayStatus.missed:
        sb.write('M');
      default:
        sb.write('.');
    }
  }
  return sb.toString();
}

/// Runs the pattern over its full range (stopDate pinned to the leftmost day so
/// every day resolves to a definite S/F/M) and returns the result.
StreakResult _run(String pattern, DateTime today) => StreakService.computeStreak(
      sessions: _sessionsFromPattern(pattern, today),
      stopDate: _patternStart(pattern, today),
      now: today,
    );

void main() {
  // Anchor "today" at Thursday 2026-04-23 so patterns straddle the Mon–Sun week
  // boundary (Sun 04-19 | Mon 04-20) — used by the original canonical cases.
  final thursday = DateTime(2026, 4, 23);

  // Anchor "today" at Sunday 2026-04-26 so a 7-day pattern is one whole Mon–Sun
  // week (Mon 04-20 … Sun 04-26) — used by the user's examples so the 2/week
  // freeze budget applies across the entire pattern.
  final sunday = DateTime(2026, 4, 26);

  group('StreakService.computeStreak — canonical examples', () {
    test('MMMSMMM → 0 (today missed, 2 freezes used, 3rd miss breaks)', () {
      expect(
        StreakService.computeStreak(
                sessions: _sessionsFromPattern('MMMSMMM', thursday),
                now: thursday)
            .streak,
        0,
      );
    });

    test('SSSSSFF → 5 (2 trailing freezes reach today alive)', () {
      expect(
        StreakService.computeStreak(
                sessions: _sessionsFromPattern('SSSSSFF', thursday),
                now: thursday)
            .streak,
        5,
      );
    });

    test('SSSFSSS → 6 (single mid-week freeze bridges the gap)', () {
      expect(
        StreakService.computeStreak(
                sessions: _sessionsFromPattern('SSSFSSS', thursday),
                now: thursday)
            .streak,
        6,
      );
    });

    test('SSFFSSS → 5 (two consecutive freezes bridge the gap)', () {
      expect(
        StreakService.computeStreak(
                sessions: _sessionsFromPattern('SSFFSSS', thursday),
                now: thursday)
            .streak,
        5,
      );
    });

    test('SFSSSSF → 5 (freezes split across week boundary, both within budget)',
        () {
      expect(
        StreakService.computeStreak(
                sessions: _sessionsFromPattern('SFSSSSF', thursday),
                now: thursday)
            .streak,
        5,
      );
    });

    test('MMMSSD → 2 (today has no alarm, 2 sessions before 3-miss break)', () {
      // D in the user's notation = today with no completed session.
      expect(
        StreakService.computeStreak(
                sessions: _sessionsFromPattern('MMMSSM', thursday),
                now: thursday)
            .streak,
        2,
      );
    });
  });

  group('StreakService.computeStreak — user examples (single Mon–Sun week)', () {
    // Each string is the expected per-day status (S=done, F=freeze, M=missed);
    // the streak is the run of consecutive S reaching today.
    test('MSFSMMM — one mid freeze, dead tail becomes all misses → streak 0',
        () {
      final r = _run('MSFSMMM', sunday);
      expect(_statusString(r, 'MSFSMMM', sunday), 'MSFSMMM');
      expect(r.streak, 0);
    });

    test('MSFFSMM — two consecutive freezes bridge, tail over budget → streak 0',
        () {
      final r = _run('MSFFSMM', sunday);
      expect(_statusString(r, 'MSFFSMM', sunday), 'MSFFSMM');
      expect(r.streak, 0);
    });

    test('MSFFMSS — middle freezes kept even though the gap breaks → streak 2',
        () {
      final r = _run('MSFFMSS', sunday);
      expect(_statusString(r, 'MSFFMSS', sunday), 'MSFFMSS');
      expect(r.streak, 2);
    });

    test('MSFSFSM — two split freezes, tail over budget → streak 0', () {
      final r = _run('MSFSFSM', sunday);
      expect(_statusString(r, 'MSFSFSM', sunday), 'MSFSFSM');
      expect(r.streak, 0);
    });
  });

  group('StreakService.computeStreak — freeze rules', () {
    test('middle gap keeps freezes when the streak restarts afterward', () {
      // MSFFMSS: d2,d3 froze but the gap broke at d4; they stay F because a
      // later validated day exists.
      expect(_statusString(_run('MSFFMSS', sunday), 'MSFFMSS', sunday),
          'MSFFMSS');
    });

    test('dead tail reverts its speculative freezes to misses', () {
      // MSFSMMM: the trailing run never reaches an alive today, so its freezes
      // become misses rather than showing F.
      expect(_statusString(_run('MSFSMMM', sunday), 'MSFSMMM', sunday),
          'MSFSMMM');
    });

    test('2-consecutive cap persists across a Mon–Sun boundary', () {
      // thursday anchor: S Fri17, freezes Sat18+Sun19 (week A, 2 freezes), then
      // Mon20 starts a fresh weekly budget but is the 3rd consecutive freeze →
      // it breaks anyway. Middle freezes are kept because S returns later.
      final r = _run('SMMMMSS', thursday);
      expect(_statusString(r, 'SMMMMSS', thursday), 'SFFMMSS');
      expect(r.streak, 2);
    });

    test('trailing tail alive within budget keeps the streak', () {
      // SSSSSFF: two trailing freezes reach today alive → streak 5.
      final r = _run('SSSSSFF', thursday);
      expect(r.streak, 5);
      // Today (rightmost) is internally frozen but excluded from the display.
      expect(r.frozenDays.contains(_key(thursday)), isFalse);
      expect(r.weekDays[thursday.weekday % 7], DayStatus.none);
    });

    test('trailing tail over budget breaks the streak → all misses', () {
      // SSSSMMM: 3 trailing unvalidated days exceed the freeze budget.
      final r = _run('SSSSMMM', thursday);
      expect(_statusString(r, 'SSSSMMM', thursday), 'SSSSMMM');
      expect(r.streak, 0);
    });

    test('alternating validations spend the weekly budget then break', () {
      // SMSMSMS in one week: freezes at the 2nd and 4th days, the 6th cannot
      // freeze (budget spent) so it breaks; today restarts the streak at 1.
      final r = _run('SMSMSMS', sunday);
      expect(_statusString(r, 'SMSMSMS', sunday), 'SFSFSMS');
      expect(r.streak, 1);
    });
  });

  group('StreakService.computeStreak — screen-time disable', () {
    test('a screen-time-disabled day is a freezable miss that bridges', () {
      // SXS: the middle day is un-validated by screen-time but a freeze bridges
      // the two wake-ups.
      final r = _run('SXS', sunday);
      expect(_statusString(r, 'SXS', sunday), 'SFS');
      expect(r.streak, 2);
    });

    test('two screen-time-disabled days still bridge (2 consecutive freezes)',
        () {
      final r = _run('SXXS', sunday);
      expect(_statusString(r, 'SXXS', sunday), 'SFFS');
      expect(r.streak, 2);
    });

    test('three screen-time-disabled days break the streak', () {
      // SXXXS: the 3rd disabled day exceeds the consecutive cap and breaks; the
      // streak restarts at the final wake-up.
      final r = _run('SXXXS', sunday);
      expect(_statusString(r, 'SXXXS', sunday), 'SFFMS');
      expect(r.streak, 1);
    });

    test('screen-time disable un-validates a day that also had a wake-up', () {
      // Same day has both a completed wake-up and a screen-time-disable → the
      // day counts as a freezable miss, bridged here by a single freeze.
      final today = sunday;
      final sessions = [
        _session(DateTime(today.year, today.month, today.day - 2)),
        _session(DateTime(today.year, today.month, today.day - 1)),
        _screenTimeDisabled(DateTime(today.year, today.month, today.day - 1)),
        _session(today),
      ];
      final r = StreakService.computeStreak(
        sessions: sessions,
        stopDate: DateTime(today.year, today.month, today.day - 2),
        now: today,
      );
      expect(_statusString(r, 'SXS', today), 'SFS');
      expect(r.streak, 2);
    });
  });

  group('StreakService.computeStreak — edge cases', () {
    test('empty sessions → 0 streak, all weekDays none', () {
      final result =
          StreakService.computeStreak(sessions: const [], now: thursday);
      expect(result.streak, 0);
      expect(result.weekDays, List.filled(7, DayStatus.none));
    });

    test('only today has a session → streak 1, today shows done', () {
      final result =
          StreakService.computeStreak(sessions: [_session(thursday)], now: thursday);
      expect(result.streak, 1);
      // 2026-04-23 is Thursday → index 4 in Sun..Sat.
      expect(result.weekDays[4], DayStatus.done);
      expect(result.weekDays.where((s) => s == DayStatus.done).length, 1);
    });

    test('today display stays none even when freeze applied internally', () {
      // SSSSSFF: today has no session, but internally consumes a freeze.
      final result = StreakService.computeStreak(
          sessions: _sessionsFromPattern('SSSSSFF', thursday), now: thursday);
      expect(result.weekDays[4], DayStatus.none); // Thursday index = 4
    });

    test('incomplete sessions are ignored', () {
      final incomplete = WakeupSession(
        id: 'incomplete',
        timestamp: thursday,
        timeTakenSeconds: 0,
        completed: false,
      );
      final result = StreakService.computeStreak(
        sessions: [incomplete],
        now: thursday,
      );
      expect(result.streak, 0);
    });

    test('all-missed week over its whole range → streak 0, all missed', () {
      final r = _run('MMMMMMM', sunday);
      expect(_statusString(r, 'MMMMMMM', sunday), 'MMMMMMM');
      expect(r.streak, 0);
    });

    test('stopDate override halts walk before exhausting freezes', () {
      final ancient =
          _session(DateTime(thursday.year, thursday.month, thursday.day - 30));
      final result = StreakService.computeStreak(
        sessions: [ancient],
        stopDate: DateTime(thursday.year, thursday.month, thursday.day - 1),
        now: thursday,
      );
      expect(result.streak, 0);
    });

    test('frozen days feed the heatmap set across full history', () {
      // MSFFMSS has two historical freezes (d2,d3) in a broken streak; both must
      // appear in frozenDays so the heatmap renders them, unlike the old walk
      // that stopped at the first break.
      final r = _run('MSFFMSS', sunday);
      final d2 = DateTime(sunday.year, sunday.month, sunday.day - 4);
      final d3 = DateTime(sunday.year, sunday.month, sunday.day - 3);
      expect(r.frozenDays, containsAll([_key(d2), _key(d3)]));
    });
  });
}
