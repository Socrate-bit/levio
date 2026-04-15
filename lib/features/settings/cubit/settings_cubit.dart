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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    final keepAlarm = prefs.getBool(_keepAlarmKey) ?? false;
    final soundId = prefs.getString(_defaultSoundIdKey) ?? 'default';
    final soundName = prefs.getString(_defaultSoundNameKey) ?? 'Default';
    final missionStr = prefs.getString(_defaultMissionKey);
    final mission =
        missionStr != null ? missionTypeFromString(missionStr) : MissionType.none;

    emit(SettingsState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      keepAlarmDuringMission: keepAlarm,
      defaultSoundId: soundId,
      defaultSoundName: soundName,
      defaultMission: mission,
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
    final next = !state.keepAlarmDuringMission;
    emit(state.copyWith(keepAlarmDuringMission: next));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepAlarmKey, next);
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
}
