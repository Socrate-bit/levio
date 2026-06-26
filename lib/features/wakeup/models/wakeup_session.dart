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

  const WakeupSession({
    required this.id,
    this.alarmId,
    required this.timestamp,
    required this.timeTakenSeconds,
    this.missionType,
    this.soundId = 'default',
    this.completed = true,
    this.autoDismissed = false,
  });

  Map<String, dynamic> toFirestore() => {
        'alarmId': alarmId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'timeTakenSeconds': timeTakenSeconds,
        'missionType': missionType?.name,
        'soundId': soundId,
        'completed': completed,
        'autoDismissed': autoDismissed,
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
    );
  }
}
