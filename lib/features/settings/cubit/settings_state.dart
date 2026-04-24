import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../missions/models/mission.dart';

/// All app-level preferences (theme, defaults, behaviour toggles).
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool keepAlarmDuringMission;
  final String defaultSoundId;
  final String defaultSoundName;
  final MissionType defaultMission;
  final bool forceQuickAlarm;
  // Admin/UGC only — forces the photo-hunt roulette to always land on this
  // item label, regardless of which items are selected for the mission.
  // null = random (default).
  final String? forcedHuntTarget;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.keepAlarmDuringMission = false,
    this.defaultSoundId = 'default',
    this.defaultSoundName = 'Default',
    this.defaultMission = MissionType.none,
    this.forceQuickAlarm = false,
    this.forcedHuntTarget,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? keepAlarmDuringMission,
    String? defaultSoundId,
    String? defaultSoundName,
    MissionType? defaultMission,
    bool? forceQuickAlarm,
    String? forcedHuntTarget,
    bool clearForcedHuntTarget = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      keepAlarmDuringMission:
          keepAlarmDuringMission ?? this.keepAlarmDuringMission,
      defaultSoundId: defaultSoundId ?? this.defaultSoundId,
      defaultSoundName: defaultSoundName ?? this.defaultSoundName,
      defaultMission: defaultMission ?? this.defaultMission,
      forceQuickAlarm: forceQuickAlarm ?? this.forceQuickAlarm,
      forcedHuntTarget:
          clearForcedHuntTarget ? null : (forcedHuntTarget ?? this.forcedHuntTarget),
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        keepAlarmDuringMission,
        defaultSoundId,
        defaultSoundName,
        defaultMission,
        forceQuickAlarm,
        forcedHuntTarget,
      ];
}
