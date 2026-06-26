import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/screentime_schedule.dart';
import '../services/screentime_channel.dart';
import '../services/screentime_firestore_service.dart';
import 'screentime_state.dart';

/// Owns the screen-time config and the unlock flow. Registered globally in
/// `app.dart` so its lifecycle observer outlives navigation (the home chip and
/// the detail screen are both descendants).
///
/// Every config change is persisted to three sinks: SharedPreferences (fast
/// local cache), Firestore (cross-device sync), and the native bridge (which
/// drives the actual blocking). On load Firestore is the source of truth, with
/// the local cache as the offline fallback.
class ScreenTimeCubit extends Cubit<ScreenTimeState> with WidgetsBindingObserver {
  ScreenTimeCubit() : super(ScreenTimeState(now: DateTime.now())) {
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startStatusTicker();
  }

  static const _enabledKey = 'screentime_enabled';
  static const _schedulesKey = 'screentime_schedules';

  Timer? _statusTicker;
  Timer? _unlockTimer;

  // ---------------------------------------------------------------------------
  // Loading & persistence
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    final now = DateTime.now();
    // 1. Local cache (fast, offline-safe).
    final prefs = await SharedPreferences.getInstance();
    var enabled = prefs.getBool(_enabledKey) ?? false;
    var schedules = _decodeSchedules(prefs.getString(_schedulesKey));

    // 2. Firestore as source of truth when reachable.
    try {
      final remote = await ScreenTimeFirestoreService.load();
      if (remote != null) {
        enabled = remote.enabled;
        schedules = remote.schedules;
        await _writeCache(prefs, enabled, schedules);
      }
    } catch (e) {
      debugPrint('[ScreenTimeCubit] Firestore load failed: $e');
    }

    // 3. Native state (authorization + current selection).
    final authStr = await ScreenTimeChannel.authorizationStatus();
    final count = await ScreenTimeChannel.selectedAppCount();

    emit(state.copyWith(
      enabled: enabled,
      schedules: schedules,
      selectedAppCount: count,
      auth: _parseAuth(authStr),
      loading: false,
      now: now,
    ));

    // 4. Make sure native monitoring matches the resolved config.
    await ScreenTimeChannel.applySchedules(enabled, schedules);
  }

  /// Persists the current enabled flag + schedules to all three sinks.
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await _writeCache(prefs, state.enabled, state.schedules);
    try {
      await ScreenTimeFirestoreService.save(state.enabled, state.schedules);
    } catch (e) {
      debugPrint('[ScreenTimeCubit] Firestore save failed: $e');
    }
    await ScreenTimeChannel.applySchedules(state.enabled, state.schedules);
  }

  Future<void> _writeCache(
    SharedPreferences prefs,
    bool enabled,
    List<ScreenTimeSchedule> schedules,
  ) async {
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setString(
      _schedulesKey,
      jsonEncode(schedules.map((s) => s.toJson()).toList()),
    );
  }

  List<ScreenTimeSchedule> _decodeSchedules(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              ScreenTimeSchedule.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[ScreenTimeCubit] schedule decode failed: $e');
      return const [];
    }
  }

  ScreenTimeAuth _parseAuth(String s) => switch (s) {
        'approved' => ScreenTimeAuth.approved,
        'denied' => ScreenTimeAuth.denied,
        _ => ScreenTimeAuth.notDetermined,
      };

  // ---------------------------------------------------------------------------
  // Config mutations (blocked while controls are locked — UI also guards this)
  // ---------------------------------------------------------------------------

  /// Requests Family Controls authorization if not already approved. Returns
  /// whether the feature is authorized afterwards.
  Future<bool> requestAuthorizationIfNeeded() async {
    if (state.auth == ScreenTimeAuth.approved) return true;
    final granted = await ScreenTimeChannel.requestAuthorization();
    emit(state.copyWith(
      auth: granted ? ScreenTimeAuth.approved : ScreenTimeAuth.denied,
    ));
    return granted;
  }

  Future<void> setEnabled(bool value) async {
    if (state.controlsLocked) return;
    if (value && state.auth != ScreenTimeAuth.approved) {
      final granted = await requestAuthorizationIfNeeded();
      if (!granted) return; // leave disabled; UI surfaces the denial
    }
    emit(state.copyWith(enabled: value, now: DateTime.now()));
    await _persist();
  }

  Future<void> addSchedule(ScreenTimeSchedule schedule) async {
    if (state.controlsLocked) return;
    emit(state.copyWith(
      schedules: [...state.schedules, schedule],
      now: DateTime.now(),
    ));
    await _persist();
  }

  Future<void> updateSchedule(ScreenTimeSchedule schedule) async {
    if (state.controlsLocked) return;
    emit(state.copyWith(
      schedules: [
        for (final s in state.schedules)
          if (s.id == schedule.id) schedule else s,
      ],
      now: DateTime.now(),
    ));
    await _persist();
  }

  Future<void> removeSchedule(String id) async {
    if (state.controlsLocked) return;
    emit(state.copyWith(
      schedules: state.schedules.where((s) => s.id != id).toList(),
      now: DateTime.now(),
    ));
    await _persist();
  }

  Future<void> toggleSchedule(String id, bool value) async {
    if (state.controlsLocked) return;
    emit(state.copyWith(
      schedules: [
        for (final s in state.schedules)
          if (s.id == id) s.copyWith(enabled: value) else s,
      ],
      now: DateTime.now(),
    ));
    await _persist();
  }

  /// Presents the native app picker and updates the selection count.
  Future<void> pickApps() async {
    if (state.controlsLocked) return;
    if (state.auth != ScreenTimeAuth.approved) {
      final granted = await requestAuthorizationIfNeeded();
      if (!granted) return;
    }
    final count = await ScreenTimeChannel.pickApps();
    emit(state.copyWith(selectedAppCount: count, now: DateTime.now()));
    // Re-apply so the shield reflects the new selection immediately.
    await ScreenTimeChannel.applySchedules(state.enabled, state.schedules);
  }

  // ---------------------------------------------------------------------------
  // Unlock flow (lives entirely here so the focus-reset and visible countdown
  // stay in sync — the dialog holds no timer of its own)
  // ---------------------------------------------------------------------------

  void startUnlockCountdown() {
    _unlockTimer?.cancel();
    emit(state.copyWith(
      unlockInProgress: true,
      unlockCountdown: kUnlockCountdownSeconds,
    ));
    _unlockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickUnlock());
  }

  void _tickUnlock() {
    final next = state.unlockCountdown - 1;
    if (next <= 0) {
      _unlockTimer?.cancel();
      // Countdown complete: the unlock button becomes available but nothing
      // unlocks automatically — the user must tap it (see [confirmUnlock]).
      emit(state.copyWith(unlockCountdown: 0));
    } else {
      emit(state.copyWith(unlockCountdown: next));
    }
  }

  /// User tapped the unlock button after the countdown finished.
  void confirmUnlock() {
    if (!state.unlockReady) return;
    _unlockTimer?.cancel();
    emit(state.copyWith(
      controlsUnlocked: true,
      unlockInProgress: false,
      unlockCountdown: 0,
    ));
  }

  /// User dismissed the countdown dialog without finishing.
  void cancelUnlock() {
    _unlockTimer?.cancel();
    emit(state.copyWith(unlockInProgress: false, unlockCountdown: 0));
  }

  /// Re-locks the controls (called when leaving the detail screen).
  void relock() {
    _unlockTimer?.cancel();
    emit(state.copyWith(
      controlsUnlocked: false,
      unlockInProgress: false,
      unlockCountdown: 0,
    ));
  }

  // ---------------------------------------------------------------------------
  // Lifecycle: reset the countdown whenever the app loses focus.
  // ---------------------------------------------------------------------------

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed && state.unlockInProgress) {
      // Strict, sleep-protective: any loss of focus restarts the full countdown
      // (even after it had finished and was awaiting the unlock tap).
      startUnlockCountdown();
    }
  }

  // ---------------------------------------------------------------------------
  // Status ticker: advances `now` so isActiveNow / status recompute, and
  // re-locks once a window ends.
  // ---------------------------------------------------------------------------

  void _startStatusTicker() {
    _statusTicker = Timer.periodic(const Duration(seconds: 20), (_) {
      final now = DateTime.now();
      final stillActive = state.enabled &&
          state.hasSelectedApps &&
          state.schedules.any((s) => s.isActiveAt(now));
      emit(state.copyWith(
        now: now,
        // Auto re-lock when the active window has closed.
        controlsUnlocked: stillActive ? state.controlsUnlocked : false,
      ));
    });
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTicker?.cancel();
    _unlockTimer?.cancel();
    return super.close();
  }
}
