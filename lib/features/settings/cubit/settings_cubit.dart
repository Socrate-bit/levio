import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../missions/models/mission.dart';
import 'settings_state.dart';

/// Manages all app-level settings (theme, alarm defaults, behaviour toggles).
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  static const _themeKey = 'theme_mode';
  static const _keepAlarmKey = 'keep_alarm_during_mission';
  static const _defaultSoundIdKey = 'default_sound_id';
  static const _defaultSoundNameKey = 'default_sound_name';
  static const _defaultMissionKey = 'default_mission';
  static const forceQuickAlarmKey = 'force_quick_alarm';
  static const forcedHuntTargetKey = 'forced_hunt_target';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    final keepAlarm = prefs.getBool(_keepAlarmKey) ?? false;
    final soundId = prefs.getString(_defaultSoundIdKey) ?? 'default';
    final soundName = prefs.getString(_defaultSoundNameKey) ?? 'Default';
    final missionStr = prefs.getString(_defaultMissionKey);
    final mission =
        missionStr != null ? missionTypeFromString(missionStr) : MissionType.none;
    final forceQuickAlarm = prefs.getBool(forceQuickAlarmKey) ?? false;
    final forcedHuntTarget = prefs.getString(forcedHuntTargetKey);

    emit(SettingsState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      keepAlarmDuringMission: keepAlarm,
      defaultSoundId: soundId,
      defaultSoundName: soundName,
      defaultMission: mission,
      forceQuickAlarm: forceQuickAlarm,
      forcedHuntTarget: forcedHuntTarget,
    ));
  }

  Future<void> toggleTheme() async {
    final next =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(state.copyWith(themeMode: next));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, next == ThemeMode.dark);
  }

  Future<void> toggleKeepAlarmDuringMission() async {
    await setKeepAlarmDuringMission(!state.keepAlarmDuringMission);
  }

  Future<void> setKeepAlarmDuringMission(bool value) async {
    if (state.keepAlarmDuringMission == value) return;
    emit(state.copyWith(keepAlarmDuringMission: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepAlarmKey, value);
  }

  Future<void> setDefaultSound(String id, String name) async {
    emit(state.copyWith(defaultSoundId: id, defaultSoundName: name));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultSoundIdKey, id);
    await prefs.setString(_defaultSoundNameKey, name);
  }

  Future<void> setDefaultMission(MissionType type) async {
    emit(state.copyWith(defaultMission: type));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultMissionKey, type.name);
  }

  Future<void> toggleForceQuickAlarm() async {
    final next = !state.forceQuickAlarm;
    emit(state.copyWith(forceQuickAlarm: next));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(forceQuickAlarmKey, next);
  }

  /// Admin/UGC: forces the photo-hunt roulette to always land on [label].
  /// Pass null to clear and restore random selection.
  Future<void> setForcedHuntTarget(String? label) async {
    emit(state.copyWith(
      forcedHuntTarget: label,
      clearForcedHuntTarget: label == null,
    ));
    final prefs = await SharedPreferences.getInstance();
    if (label == null) {
      await prefs.remove(forcedHuntTargetKey);
    } else {
      await prefs.setString(forcedHuntTargetKey, label);
    }
  }

  /// Debug: dumps every SharedPreferences key/value.
  Future<void> printSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[SettingsCubit] SharedPreferences (${keys.length} keys):');
    for (final key in keys) {
      final value = prefs.get(key);
      debugPrint('  $key = $value  (${value.runtimeType})');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Wipes all persisted settings and resets state to defaults. Called on
  /// logout so the next account starts from a clean slate.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_themeKey),
      prefs.remove(_keepAlarmKey),
      prefs.remove(_defaultSoundIdKey),
      prefs.remove(_defaultSoundNameKey),
      prefs.remove(_defaultMissionKey),
      prefs.remove(forceQuickAlarmKey),
      prefs.remove(forcedHuntTargetKey),
    ]);
    emit(const SettingsState());
  }
}
