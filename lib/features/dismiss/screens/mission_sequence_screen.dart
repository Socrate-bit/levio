import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_channel.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import 'mission_start_screen.dart';

/// Orchestrates a multi-mission dismiss flow (up to 3 missions in sequence).
class MissionSequenceScreen extends StatefulWidget {
  final List<MissionConfig> missions;
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;

  const MissionSequenceScreen({
    super.key,
    required this.missions,
    required this.alarmId,
    required this.nativeAlarmId,
    required this.alarmLabel,
  });

  @override
  State<MissionSequenceScreen> createState() => _MissionSequenceScreenState();
}

class _MissionSequenceScreenState extends State<MissionSequenceScreen> {
  int _currentIndex = 0;
  bool _inMission = false;
  String? _missionSnoozeId;
  final _startTime = DateTime.now();

  /// Resolved mission types (random missions are resolved once at init).
  late final List<MissionConfig> _resolvedMissions;

  @override
  void initState() {
    super.initState();
    _resolvedMissions = widget.missions.map(_resolveRandom).toList();
    _initAlarm();
  }

  /// Resolves a random mission config to a concrete mission type.
  MissionConfig _resolveRandom(MissionConfig config) {
    if (config.type != MissionType.random) return config;

    final pool = (config.randomPool != null && config.randomPool!.isNotEmpty)
        ? config.randomPool!
        : MissionType.values
            .where((t) => t != MissionType.none && t != MissionType.random)
            .toList();
    final picked = (List<MissionType>.from(pool)..shuffle()).first;
    return config.copyWith(type: picked);
  }

  Future<void> _initAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;
    if (!keepRinging) {
      await AlarmChannel.dismissAlarm(widget.nativeAlarmId);
      _missionSnoozeId = await AlarmChannel.scheduleMissionSnooze(
        nativeAlarmId: widget.nativeAlarmId,
        originalAlarmId: widget.alarmId,
      );
    }
  }

  void _startMission() {
    setState(() => _inMission = true);

    final config = _resolvedMissions[_currentIndex];
    final screen = buildDismissScreen(
      config: config,
      alarmId: widget.alarmId,
      nativeAlarmId: widget.nativeAlarmId,
      alarmLabel: widget.alarmLabel,
      manageAlarm: false,
      onComplete: _onMissionComplete,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      // If popped without completing (shouldn't happen normally)
      if (mounted) setState(() => _inMission = false);
    });
  }

  void _onMissionComplete() {
    // Pop the dismiss screen
    Navigator.of(context).pop();

    if (_currentIndex + 1 < _resolvedMissions.length) {
      setState(() {
        _currentIndex++;
        _inMission = false;
      });
    } else {
      _finishSequence();
    }
  }

  Future<void> _finishSequence() async {
    await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
    await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
    await AlarmChannel.stopRinging();

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            nativeAlarmId: widget.nativeAlarmId,
            timeTakenSeconds: elapsed,
            missionType: _resolvedMissions.first.type,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MissionStartScreen(
      currentIndex: _currentIndex,
      totalMissions: _resolvedMissions.length,
      missionType: _resolvedMissions[_currentIndex].type,
      onStart: _startMission,
    );
  }
}
