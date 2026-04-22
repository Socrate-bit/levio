import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import 'mission_start_screen.dart';

/// Orchestrates a multi-mission dismiss flow (up to 3 missions in sequence).
///
/// Owns the [AlarmCascadeController] for the whole sequence. The controller
/// is started the moment the user taps "Start" on the current mission-start
/// screen and is finished when the final mission completes. If the user goes
/// inactive for 60s on any in-progress mission, we pop back to the mission
/// start screen and pause the suppression timer so bursts resume ringing.
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
  final _startTime = DateTime.now();
  late final AlarmCascadeController _cascade;

  late final List<MissionConfig> _resolvedMissions;

  @override
  void initState() {
    super.initState();
    _resolvedMissions = widget.missions.map(_resolveRandom).toList();
    _cascade = AlarmCascadeController(
      alarmId: widget.alarmId,
      onInactivityTimeout: _onInactivityTimeout,
    );
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

  void _startMission() {
    // Mission has now officially "started" — fire up suppression + watchdog.
    _cascade.start();
    setState(() => _inMission = true);

    final config = _resolvedMissions[_currentIndex];
    final screen = buildDismissScreen(
      config: config,
      alarmId: widget.alarmId,
      nativeAlarmId: widget.nativeAlarmId,
      alarmLabel: widget.alarmLabel,
      manageAlarm: false,
      onProgress: _cascade.reportProgress,
      onComplete: _onMissionComplete,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (mounted) setState(() => _inMission = false);
    });
  }

  void _onMissionComplete() {
    Navigator.of(context).pop();

    if (_currentIndex + 1 < _resolvedMissions.length) {
      // Next mission will restart suppression when the user taps Start.
      _cascade.stopSuppression();
      setState(() {
        _currentIndex++;
        _inMission = false;
      });
    } else {
      _finishSequence();
    }
  }

  /// Fired by the cascade controller when the user has gone idle for 60s on
  /// an in-progress mission. Pops the mission screen, returns to the start
  /// screen, and lets bursts resume ringing until the user taps Start again.
  void _onInactivityTimeout() {
    if (!mounted) return;
    if (!_inMission) return;
    // Pop the in-progress mission screen back to this MissionStartScreen.
    Navigator.of(context).popUntil((route) => route.isFirst || route.isCurrent);
    if (mounted) setState(() => _inMission = false);
  }

  Future<void> _finishSequence() async {
    await _cascade.finish();

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
  void dispose() {
    _cascade.dispose();
    super.dispose();
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
