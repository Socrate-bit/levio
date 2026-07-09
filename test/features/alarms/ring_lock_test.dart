import 'package:flutter_test/flutter_test.dart';
import 'package:levio/features/alarms/cubit/alarm_state.dart';

// repeatDays index: Sun=0 … Sat=6.
AppAlarmEntry _alarm({
  required DateTime dateTime,
  List<bool>? repeatDays,
  bool isOneTime = false,
}) =>
    AppAlarmEntry(
      id: 'test',
      dateTime: dateTime,
      repeatDays: repeatDays ?? List.filled(7, true),
      isOneTime: isOneTime,
    );

void main() {
  group('AppAlarmEntry.activeRingStart', () {
    test('one-time alarm locks within the 30-minute window', () {
      final a = _alarm(dateTime: DateTime(2026, 6, 24, 7, 0), isOneTime: true);
      // At fire time and 29 min later → locked.
      expect(a.activeRingStart(DateTime(2026, 6, 24, 7, 0)),
          DateTime(2026, 6, 24, 7, 0));
      expect(a.activeRingStart(DateTime(2026, 6, 24, 7, 29)),
          DateTime(2026, 6, 24, 7, 0));
      // At/after 30 min → unlocked (window end exclusive).
      expect(a.activeRingStart(DateTime(2026, 6, 24, 7, 30)), isNull);
      // Before fire time → unlocked.
      expect(a.activeRingStart(DateTime(2026, 6, 24, 6, 59)), isNull);
    });

    test('repeating alarm locks only on an active weekday', () {
      // Fires 07:00; active Mon–Fri (Sun=0 false, Sat=6 false).
      final weekdays = [false, true, true, true, true, true, false];
      final a = _alarm(dateTime: DateTime(2026, 6, 24, 7, 0), repeatDays: weekdays);
      // Wednesday 2026-06-24 within window → locked.
      expect(a.activeRingStart(DateTime(2026, 6, 24, 7, 10)),
          DateTime(2026, 6, 24, 7, 0));
      // Saturday 2026-06-27 (inactive day) → unlocked even within the time.
      expect(a.activeRingStart(DateTime(2026, 6, 27, 7, 10)), isNull);
    });

    test('window crossing midnight still locks the previous day fire', () {
      // Fires 23:50 daily. At 00:10 the next day, 20 min into the window.
      final a = _alarm(dateTime: DateTime(2026, 6, 24, 23, 50));
      expect(a.activeRingStart(DateTime(2026, 6, 25, 0, 10)),
          DateTime(2026, 6, 24, 23, 50));
      // 21 min after midnight is 31 min past fire → unlocked.
      expect(a.activeRingStart(DateTime(2026, 6, 25, 0, 21)), isNull);
    });
  });
}
