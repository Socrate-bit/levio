import '../../missions/models/mission.dart';

class WakeupSession {
  final String id;
  final String? alarmId;
  final DateTime timestamp;
  final int timeTakenSeconds;
  final MissionType? missionType;
  final String soundId;
  final bool completed;
  final bool spinToWinUsed;

  const WakeupSession({
    required this.id,
    this.alarmId,
    required this.timestamp,
    required this.timeTakenSeconds,
    this.missionType,
    this.soundId = 'default',
    this.completed = true,
    this.spinToWinUsed = false,
  });

  Map<String, dynamic> toFirestore() => {
        'alarmId': alarmId,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'timeTakenSeconds': timeTakenSeconds,
        'missionType': missionType?.name,
        'soundId': soundId,
        'completed': completed,
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
      spinToWinUsed: (data['spinToWinUsed'] as bool?) ?? false,
    );
  }
}
