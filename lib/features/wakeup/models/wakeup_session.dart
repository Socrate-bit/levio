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

  /// True when this entry records a screen-time relapse (the user unlocked the
  /// block during an active window) rather than an alarm. Always incomplete;
  /// counts as a missed day for the streak and shows a distinct history label.
  final bool relapse;

  const WakeupSession({
    required this.id,
    this.alarmId,
    required this.timestamp,
    required this.timeTakenSeconds,
    this.missionType,
    this.soundId = 'default',
    this.completed = true,
    this.autoDismissed = false,
    this.relapse = false,
  });

  Map<String, dynamic> toFirestore() => {
        'alarmId': alarmId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'timeTakenSeconds': timeTakenSeconds,
        'missionType': missionType?.name,
        'soundId': soundId,
        'completed': completed,
        'autoDismissed': autoDismissed,
        'relapse': relapse,
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
      relapse: (data['relapse'] as bool?) ?? false,
    );
  }
}
