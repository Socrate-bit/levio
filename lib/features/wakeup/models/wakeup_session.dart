import '../../missions/models/mission.dart';

class WakeupSession {
  final String id;
  final String? alarmId;
  final DateTime timestamp;
  final int timeTakenSeconds;
  final MissionType? missionType;
  final String soundId;
  final bool completed;

  /// True when this alarm was silently dismissed because another alarm ringing
  /// at the same time had its mission completed. These don't count toward
  /// totalWakeups (one physical wake-up, not several).
  final bool autoDismissed;

  /// True when this entry records the user deactivating screen-time blocking
  /// (unlocking the controls during an active window) rather than an alarm.
  /// Always incomplete; counts as a missed day for the streak and shows its own
  /// distinct history entry (not styled as a missed alarm).
  final bool screenTimeDisabled;

  /// True once the user has spun the Spin to Win bonus wheel for this session.
  /// Enforces one spin per day.
  final bool spinToWinUsed;

  const WakeupSession({
    required this.id,
    this.alarmId,
    required this.timestamp,
    required this.timeTakenSeconds,
    this.missionType,
    this.soundId = 'default',
    this.completed = true,
    this.autoDismissed = false,
    this.screenTimeDisabled = false,
    this.spinToWinUsed = false,
  });

  Map<String, dynamic> toFirestore() => {
        'alarmId': alarmId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'timeTakenSeconds': timeTakenSeconds,
        'missionType': missionType?.name,
        'soundId': soundId,
        'completed': completed,
        'autoDismissed': autoDismissed,
        'screenTimeDisabled': screenTimeDisabled,
        if (spinToWinUsed) 'spinToWinUsed': true,
      };

  factory WakeupSession.fromFirestore(String id, Map<String, dynamic> data) {
    final missionStr = data['missionType'] as String?;
    return WakeupSession(
      id: id,
      alarmId: data['alarmId'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data['timestamp'] as int?) ?? 0,
      ),
      timeTakenSeconds: (data['timeTakenSeconds'] as int?) ?? 0,
      missionType: missionStr != null ? missionTypeFromString(missionStr) : null,
      soundId: (data['soundId'] as String?) ?? 'default',
      completed: (data['completed'] as bool?) ?? true, // legacy docs are completed
      autoDismissed: (data['autoDismissed'] as bool?) ?? false,
      screenTimeDisabled: (data['screenTimeDisabled'] as bool?) ?? false,
      spinToWinUsed: (data['spinToWinUsed'] as bool?) ?? false,
    );
  }
}
