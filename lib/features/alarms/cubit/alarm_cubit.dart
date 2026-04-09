import 'dart:convert';

import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../missions/models/mission.dart';
import 'alarm_state.dart';

class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit() : super(const AlarmState()) {
    _init();
  }

  final _plugin = FlutterAlarmkit();

  // ---------------------------------------------------------------------------
  // SharedPreferences keys
  // ---------------------------------------------------------------------------
  static const _alarmIdsKey = 'alarm_ids';
  static String _missionKey(String id) => 'mission_$id';
  static String _nameKey(String id) => 'name_$id';
  static String _soundKey(String id) => 'sound_$id';
  static String _dateTimeMsKey(String id) => 'datetime_ms_$id';
  static String _isOnetimeKey(String id) => 'is_onetime_$id';
  static String _mathDiffKey(String id) => 'math_diff_$id';
  static String _customObjKey(String id) => 'custom_obj_$id';

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    await _plugin.requestAuthorization();
    await _syncAlarms();
  }

  Future<void> _syncAlarms() async {
    final rawAlarmkit = await _plugin.getAlarms();
    final prefs = await SharedPreferences.getInstance();

    // Build map of active AlarmKit alarms: id → dateTime
    final activeMap = <String, DateTime>{};
    for (final item in rawAlarmkit) {
      final id = item['id'] as String?;
      final schedule = item['schedule'] as Map?;
      if (id == null || schedule == null) continue;
      if (schedule['type'] != 'fixed') continue;
      final tsMs = schedule['timestamp'] as double?;
      if (tsMs == null) continue;
      activeMap[id] = DateTime.fromMillisecondsSinceEpoch(tsMs.toInt());
    }

    // Get all IDs we've ever tracked
    final storedIds = _getStoredIds(prefs);

    final entries = <AppAlarmEntry>[];

    // Add all active AlarmKit alarms
    for (final MapEntry(:key, :value) in activeMap.entries) {
      storedIds.add(key);
      entries.add(_buildEntry(prefs, key, value, isEnabled: true));
    }

    // Add disabled one-time alarms (fired, AlarmKit removed them, but we still show them)
    for (final id in storedIds) {
      if (activeMap.containsKey(id)) continue;
      final isOneTime = prefs.getBool(_isOnetimeKey(id)) ?? false;
      if (!isOneTime) continue;
      final dtMs = prefs.getInt(_dateTimeMsKey(id));
      if (dtMs == null) continue;
      entries.add(_buildEntry(
        prefs,
        id,
        DateTime.fromMillisecondsSinceEpoch(dtMs),
        isEnabled: false,
      ));
    }

    await _setStoredIds(prefs, storedIds);
    entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    emit(state.copyWith(alarms: entries));
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> addAlarm(AppAlarmEntry entry) async {
    var scheduled = entry.dateTime;
    if (scheduled.isBefore(DateTime.now())) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final info = missionInfoFor(entry.missionType);
    final id = await _plugin.scheduleOneShotAlarm(
      timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
      label: entry.name.isNotEmpty ? entry.name : 'Wayk — ${info.name}',
      secondaryButton: AlarmButton(
        text: info.name,
        textColor: '#FFFFFF',
        systemImageName: _systemImageFor(entry.missionType),
      ),
      secondaryButtonBehavior: AlarmSecondaryButtonBehavior.stop,
    );

    final prefs = await SharedPreferences.getInstance();
    await _persistMetadata(prefs, id, scheduled, entry);
    final storedIds = _getStoredIds(prefs);
    storedIds.add(id);
    await _setStoredIds(prefs, storedIds);

    final saved = entry.copyWith(id: id, dateTime: scheduled, isEnabled: true);
    emit(state.copyWith(alarms: [...state.alarms, saved]));
  }

  /// Edit an existing alarm. If [dateTime] changed: cancel + reschedule.
  /// Otherwise: only update metadata in prefs and state.
  Future<void> editAlarm(AppAlarmEntry original, AppAlarmEntry updated) async {
    final prefs = await SharedPreferences.getInstance();
    String finalId = original.id;
    DateTime finalDt = updated.dateTime;

    final timeChanged = original.dateTime.millisecondsSinceEpoch !=
        updated.dateTime.millisecondsSinceEpoch;

    if (timeChanged) {
      await _plugin.cancelAlarm(alarmId: original.id);

      var scheduled = updated.dateTime;
      if (scheduled.isBefore(DateTime.now())) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      finalDt = scheduled;

      final info = missionInfoFor(updated.missionType);
      finalId = await _plugin.scheduleOneShotAlarm(
        timestamp: scheduled.millisecondsSinceEpoch.toDouble(),
        label: updated.name.isNotEmpty ? updated.name : 'Wayk — ${info.name}',
        secondaryButton: AlarmButton(
          text: info.name,
          textColor: '#FFFFFF',
          systemImageName: _systemImageFor(updated.missionType),
        ),
        secondaryButtonBehavior: AlarmSecondaryButtonBehavior.stop,
      );

      final storedIds = _getStoredIds(prefs);
      storedIds.remove(original.id);
      storedIds.add(finalId);
      await _setStoredIds(prefs, storedIds);
      await _removeMetadata(prefs, original.id);
    }

    await _persistMetadata(prefs, finalId, finalDt, updated);

    final newEntry = updated.copyWith(id: finalId, dateTime: finalDt);
    emit(state.copyWith(
      alarms: state.alarms
          .map((a) => a.id == original.id ? newEntry : a)
          .toList(),
    ));
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    emit(state.copyWith(
      alarms: state.alarms
          .map((a) => a.id == id ? a.copyWith(isEnabled: enabled) : a)
          .toList(),
    ));
  }

  Future<void> removeAlarm(String id) async {
    await _plugin.cancelAlarm(alarmId: id);
    final prefs = await SharedPreferences.getInstance();
    await _removeMetadata(prefs, id);
    final storedIds = _getStoredIds(prefs);
    storedIds.remove(id);
    await _setStoredIds(prefs, storedIds);
    emit(state.copyWith(
      alarms: state.alarms.where((a) => a.id != id).toList(),
    ));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  AppAlarmEntry _buildEntry(
    SharedPreferences prefs,
    String id,
    DateTime dt, {
    required bool isEnabled,
  }) {
    final missionRaw =
        prefs.getString(_missionKey(id)) ?? prefs.getString('challenge_$id');
    final mission = missionRaw != null
        ? missionTypeFromString(missionRaw)
        : MissionType.pushUps;

    final mathDiffRaw = prefs.getString(_mathDiffKey(id));
    final mathDiff = mathDiffRaw != null
        ? MathDifficulty.values.firstWhere(
            (d) => d.name == mathDiffRaw,
            orElse: () => MathDifficulty.easy,
          )
        : MathDifficulty.easy;

    return AppAlarmEntry(
      id: id,
      dateTime: dt,
      missionType: mission,
      name: prefs.getString(_nameKey(id)) ?? '',
      soundId: prefs.getString(_soundKey(id)) ?? 'default',
      isEnabled: isEnabled,
      isOneTime: prefs.getBool(_isOnetimeKey(id)) ?? false,
      mathDifficulty: mathDiff,
      customObject: prefs.getString(_customObjKey(id)),
    );
  }

  Future<void> _persistMetadata(
    SharedPreferences prefs,
    String id,
    DateTime dt,
    AppAlarmEntry entry,
  ) async {
    await prefs.setString(_missionKey(id), entry.missionType.name);
    await prefs.setString(_nameKey(id), entry.name);
    await prefs.setString(_soundKey(id), entry.soundId);
    await prefs.setInt(_dateTimeMsKey(id), dt.millisecondsSinceEpoch);
    await prefs.setBool(_isOnetimeKey(id), entry.isOneTime);
    await prefs.setString(_mathDiffKey(id), entry.mathDifficulty.name);
    if (entry.customObject != null && entry.customObject!.isNotEmpty) {
      await prefs.setString(_customObjKey(id), entry.customObject!);
    } else {
      await prefs.remove(_customObjKey(id));
    }
  }

  Future<void> _removeMetadata(SharedPreferences prefs, String id) async {
    await prefs.remove(_missionKey(id));
    await prefs.remove(_nameKey(id));
    await prefs.remove(_soundKey(id));
    await prefs.remove(_dateTimeMsKey(id));
    await prefs.remove(_isOnetimeKey(id));
    await prefs.remove(_mathDiffKey(id));
    await prefs.remove(_customObjKey(id));
    await prefs.remove('challenge_$id');
  }

  Set<String> _getStoredIds(SharedPreferences prefs) {
    final raw = prefs.getString(_alarmIdsKey);
    if (raw == null) return {};
    final list = jsonDecode(raw) as List;
    return Set<String>.from(list.cast<String>());
  }

  Future<void> _setStoredIds(
      SharedPreferences prefs, Set<String> ids) async {
    await prefs.setString(_alarmIdsKey, jsonEncode(ids.toList()));
  }

  String _systemImageFor(MissionType type) {
    switch (type) {
      case MissionType.shakePhone:
        return 'iphone.radiowaves.left.and.right';
      case MissionType.pushUps:
      case MissionType.squats:
        return 'figure.strengthtraining.traditional';
      case MissionType.skyPhoto:
      case MissionType.makeBed:
      case MissionType.objectHunt:
      case MissionType.petHunt:
      case MissionType.natureHunt:
      case MissionType.touchGrass:
        return 'camera.fill';
      case MissionType.bibleVerse:
      case MissionType.affirmation:
        return 'mic.fill';
      case MissionType.math:
        return 'function';
      case MissionType.random:
        return 'dice.fill';
    }
  }
}
