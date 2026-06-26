import 'package:flutter_test/flutter_test.dart';
import 'package:levio/features/screentime/cubit/screentime_state.dart';
import 'package:levio/features/screentime/models/screentime_schedule.dart';

ScreenTimeSchedule _schedule({
  List<bool>? days,
  int startHour = 22,
  int startMinute = 0,
  int endHour = 7,
  int endMinute = 0,
  bool enabled = true,
}) =>
    ScreenTimeSchedule(
      id: 'test',
      enabled: enabled,
      repeatDays: days ?? List.filled(7, true),
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );

void main() {
  group('ScreenTimeSchedule.isActiveAt', () {
    test('same-day window matches inside and excludes outside', () {
      final s = _schedule(startHour: 9, startMinute: 0, endHour: 17, endMinute: 0);
      // Wednesday 2026-06-24
      expect(s.isActiveAt(DateTime(2026, 6, 24, 12, 0)), isTrue);
      expect(s.isActiveAt(DateTime(2026, 6, 24, 8, 59)), isFalse);
      expect(s.isActiveAt(DateTime(2026, 6, 24, 17, 0)), isFalse); // end exclusive
    });

    test('overnight window matches evening on start day', () {
      final s = _schedule(startHour: 22, endHour: 7);
      expect(s.isActiveAt(DateTime(2026, 6, 24, 23, 0)), isTrue);
      expect(s.isActiveAt(DateTime(2026, 6, 24, 21, 59)), isFalse);
    });

    test('overnight window matches early morning owned by previous day', () {
      // Only Wednesday enabled. The Thursday-06:00 instant belongs to the
      // Wednesday-night window.
      final days = List.filled(7, false);
      days[3] = true; // Wednesday (index 3)
      final s = _schedule(days: days, startHour: 22, endHour: 7);
      expect(s.isActiveAt(DateTime(2026, 6, 25, 6, 0)), isTrue); // Thu morning
      expect(s.isActiveAt(DateTime(2026, 6, 25, 23, 0)), isFalse); // Thu night off
    });

    test('respects per-day repeat flags', () {
      final days = List.filled(7, false);
      days[1] = true; // Monday only (index 1)
      final s = _schedule(days: days, startHour: 9, endHour: 17);
      expect(s.isActiveAt(DateTime(2026, 6, 22, 12, 0)), isTrue); // Monday
      expect(s.isActiveAt(DateTime(2026, 6, 23, 12, 0)), isFalse); // Tuesday
    });

    test('disabled schedule is never active', () {
      final s = _schedule(enabled: false, startHour: 0, endHour: 23);
      expect(s.isActiveAt(DateTime(2026, 6, 24, 12, 0)), isFalse);
    });
  });

  group('ScreenTimeState status', () {
    final now = DateTime(2026, 6, 24, 23, 0); // Wed night, inside 22→7

    test('inactive when disabled', () {
      final state = ScreenTimeState(
        enabled: false,
        schedules: [_schedule()],
        selectedAppCount: 3,
        now: now,
      );
      expect(state.isActiveNow, isFalse);
      expect(state.activeUntil, isNull);
    });

    test('active now exposes activeUntil and locks controls', () {
      final state = ScreenTimeState(
        enabled: true,
        schedules: [_schedule(startHour: 22, endHour: 7)],
        selectedAppCount: 2,
        now: now,
      );
      expect(state.isActiveNow, isTrue);
      expect(state.controlsLocked, isTrue);
      // Ends next morning at 07:00.
      expect(state.activeUntil, DateTime(2026, 6, 25, 7, 0));
    });

    test('not active without selected apps', () {
      final state = ScreenTimeState(
        enabled: true,
        schedules: [_schedule()],
        selectedAppCount: 0,
        now: now,
      );
      expect(state.isActiveNow, isFalse);
    });

    test('activeIn reports the soonest upcoming start when not yet active', () {
      final earlyEvening = DateTime(2026, 6, 24, 20, 0); // before 22:00 start
      final state = ScreenTimeState(
        enabled: true,
        schedules: [_schedule(startHour: 22, endHour: 7)],
        selectedAppCount: 1,
        now: earlyEvening,
      );
      expect(state.isActiveNow, isFalse);
      expect(state.activeIn, const Duration(hours: 2));
    });

    test('unlocked controls are not locked while active', () {
      final state = ScreenTimeState(
        enabled: true,
        schedules: [_schedule(startHour: 22, endHour: 7)],
        selectedAppCount: 2,
        controlsUnlocked: true,
        now: now,
      );
      expect(state.isActiveNow, isTrue);
      expect(state.controlsLocked, isFalse);
    });
  });
}
