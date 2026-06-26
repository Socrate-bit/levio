import 'package:equatable/equatable.dart';

import '../models/screentime_schedule.dart';

enum ScreenTimeAuth { notDetermined, approved, denied }

/// How long the user must keep the app focused before the locked controls
/// unlock. The countdown resets if the app loses focus.
const int kUnlockCountdownSeconds = 30;

class ScreenTimeState extends Equatable {
  /// Master "Activated" toggle (persisted).
  final bool enabled;

  /// Persisted list of blocking windows.
  final List<ScreenTimeSchedule> schedules;

  /// Number of apps/categories selected natively (opaque tokens live in the
  /// App Group; Dart only knows the count).
  final int selectedAppCount;

  final ScreenTimeAuth auth;
  final bool loading;

  // --- transient unlock flow (never persisted) ---
  final bool controlsUnlocked;
  final int unlockCountdown; // seconds remaining (kUnlockCountdownSeconds..0)
  final bool unlockInProgress;

  /// Wall-clock instant used to derive [isActiveNow] / status. Bumped by the
  /// cubit ticker so the UI recomputes as time passes.
  final DateTime now;

  ScreenTimeState({
    this.enabled = false,
    this.schedules = const [],
    this.selectedAppCount = 0,
    this.auth = ScreenTimeAuth.notDetermined,
    this.loading = true,
    this.controlsUnlocked = false,
    this.unlockCountdown = 0,
    this.unlockInProgress = false,
    DateTime? now,
  }) : now = now ?? DateTime(2000);

  bool get hasSelectedApps => selectedAppCount > 0;

  /// Whether any enabled schedule's window is currently open (and the feature
  /// is on with apps selected).
  bool get isActiveNow {
    if (!enabled || !hasSelectedApps) return false;
    return schedules.any((s) => s.isActiveAt(now));
  }

  /// Controls are locked whenever blocking is live and the user has not gone
  /// through the unlock flow.
  bool get controlsLocked => isActiveNow && !controlsUnlocked;

  /// When [isActiveNow], the earliest end instant among the open windows;
  /// drives the "Active until HH:MM" status. Null when not active.
  DateTime? get activeUntil {
    if (!isActiveNow) return null;
    DateTime? earliest;
    for (final s in schedules) {
      if (!s.isActiveAt(now)) continue;
      final end = s.endAfter(now);
      if (earliest == null || end.isBefore(earliest)) earliest = end;
    }
    return earliest;
  }

  /// When enabled but not currently active, the time until the soonest upcoming
  /// window start; drives the "Active in Xh Ym" status. Null otherwise.
  Duration? get activeIn {
    if (!enabled || isActiveNow) return null;
    DateTime? soonest;
    for (final s in schedules) {
      final start = s.nextStartAfter(now);
      if (start == null) continue;
      if (soonest == null || start.isBefore(soonest)) soonest = start;
    }
    return soonest?.difference(now);
  }

  ScreenTimeState copyWith({
    bool? enabled,
    List<ScreenTimeSchedule>? schedules,
    int? selectedAppCount,
    ScreenTimeAuth? auth,
    bool? loading,
    bool? controlsUnlocked,
    int? unlockCountdown,
    bool? unlockInProgress,
    DateTime? now,
  }) {
    return ScreenTimeState(
      enabled: enabled ?? this.enabled,
      schedules: schedules ?? this.schedules,
      selectedAppCount: selectedAppCount ?? this.selectedAppCount,
      auth: auth ?? this.auth,
      loading: loading ?? this.loading,
      controlsUnlocked: controlsUnlocked ?? this.controlsUnlocked,
      unlockCountdown: unlockCountdown ?? this.unlockCountdown,
      unlockInProgress: unlockInProgress ?? this.unlockInProgress,
      now: now ?? this.now,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        schedules,
        selectedAppCount,
        auth,
        loading,
        controlsUnlocked,
        unlockCountdown,
        unlockInProgress,
        now,
      ];
}
