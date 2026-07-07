import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../alarms/services/alarm_channel.dart';
import '../../milestones/services/streak_service.dart';
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
/// start screen and stop the suppression timer so bursts resume ringing.
class MissionSequenceScreen extends StatefulWidget {
  final List<MissionConfig> missions;
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  // Sleep (bedtime) alarm vs wake-up — drives the start-screen greeting.
  final bool isSleep;
  // True when launched EARLY from Home ("Start now") before the alarm rang — on
  // completion we consume today's still-scheduled occurrence instead of the
  // normal dismiss path.
  final bool earlyStart;

  const MissionSequenceScreen({
    super.key,
    required this.missions,
    required this.alarmId,
    required this.nativeAlarmId,
    required this.alarmLabel,
    this.isSleep = false,
    this.earlyStart = false,
  });

  @override
  State<MissionSequenceScreen> createState() => _MissionSequenceScreenState();
}

class _MissionSequenceScreenState extends State<MissionSequenceScreen> {
  int _currentIndex = 0;
  bool _inMission = false;
  // Current streak shown on the start screen as encouragement (0 until loaded).
  int _currentStreak = 0;
  final _startTime = DateTime.now();
  late final AlarmCascadeController _cascade;

  late final List<MissionConfig> _resolvedMissions;
  // Caches the randomly-picked target for hunt-style photo missions so an
  // inactivity remount doesn't reroll a different object on the user.
  final Map<int, String> _photoTargets = {};

  @override
  void initState() {
    super.initState();
    _resolvedMissions = widget.missions.map(_resolveRandom).toList();
    _cascade = AlarmCascadeController(
      alarmId: widget.alarmId,
      onInactivityTimeout: _onInactivityTimeout,
      earlyStart: widget.earlyStart,
    );
    // Top up the burst queue — if the user skipped prior cascades, only the
    // master may be live when the app opens. No-op when the queue is full.
    AlarmChannel.primeCascadeIfNeeded(widget.alarmId).ignore();
    _loadStreak();
  }

  // Fetches the current streak to display as encouragement on the start screen.
  Future<void> _loadStreak() async {
    final profile = await StreakService.getProfile();
    if (mounted) setState(() => _currentStreak = profile.currentStreak);
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
    var config = _resolvedMissions[_currentIndex];
    // Mission has now officially "started" — fire up suppression + watchdog.
    // The routine mission is self-paced: suppress the alarm but never bounce
    // the user back to the start screen on inactivity.
    _cascade.start(
      enableInactivityWatchdog: config.type != MissionType.routine,
    );
    setState(() => _inMission = true);

    // If the user already saw a roulette pick for this mission and was bounced
    // back by inactivity, hand back the same target as a single-item list so
    // PhotoDismissScreen skips the roulette entirely.
    final cachedTarget = _photoTargets[_currentIndex];
    if (cachedTarget != null) {
      config = config.copyWith(selectedItems: [cachedTarget]);
    }
    final missionIndex = _currentIndex;
    final screen = buildDismissScreen(
      config: config,
      alarmId: widget.alarmId,
      nativeAlarmId: widget.nativeAlarmId,
      alarmLabel: widget.alarmLabel,
      manageAlarm: false,
      onProgress: _cascade.reportProgress,
      onComplete: _onMissionComplete,
      onPhotoTargetChosen: (target) => _photoTargets[missionIndex] = target,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (mounted) setState(() => _inMission = false);
    });
  }

  void _onMissionComplete() {
    if (_currentIndex + 1 < _resolvedMissions.length) {
      // More missions coming — pop the current mission screen and advance to
      // the next mission's start screen.
      Navigator.of(context).pop();
      _cascade.stopSuppression();
      setState(() {
        _currentIndex++;
        _inMission = false;
      });
    } else {
      // Last mission — skip popping back through MissionStartScreen. Go
      // directly from the mission screen to the wakeup-complete screen so
      // the user doesn't see a one-frame flash of the start screen.
      _finishSequence();
    }
  }

  /// Fired by the cascade controller when the user has gone idle for 20s on
  /// an in-progress mission. Pops the mission screen, returns to the start
  /// screen for the CURRENT mission (same index — no previously-completed
  /// mission is redone), and lets bursts resume ringing until the user taps
  /// Start again.
  void _onInactivityTimeout() {
    if (!mounted) return;
    if (!_inMission) return;
    // _startMission pushed exactly one MaterialPageRoute on top of this
    // MissionSequenceScreen, so a single pop returns us to MissionStartScreen.
    Navigator.of(context).pop();
    if (mounted) setState(() => _inMission = false);
  }

  Future<void> _finishSequence() async {
    await _cascade.finish();
    if (!mounted) return;

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    final missionType = _resolvedMissions.first.type;
    final spinToWin = context
            .read<AlarmCubit>()
            .state
            .alarms
            .where((a) => a.id == widget.alarmId)
            .firstOrNull
            ?.spinToWin ??
        false;

    // pushAndRemoveUntil sweeps the mission screen AND the orchestrator off
    // the stack in one transition, so WakeupCompleteScreen animates in over
    // the completed mission instead of a flash of MissionStartScreen.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => WakeupCompleteScreen(
          alarmId: widget.alarmId,
          nativeAlarmId: widget.nativeAlarmId,
          timeTakenSeconds: elapsed,
          missionType: missionType,
          spinToWin: spinToWin,
        ),
      ),
      (route) => route.isFirst,
    );
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
      isSleep: widget.isSleep,
      currentStreak: _currentStreak,
    );
  }
}
