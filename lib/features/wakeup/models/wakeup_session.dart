import '../../missions/models/mission.dart';

class WakeupSession {
  final String id;
  final DateTime timestamp;
  final int timeTakenSeconds;
  final MissionType? missionType;
  final String soundId;

  const WakeupSession({
    required this.id,
    required this.timestamp,
    required this.timeTakenSeconds,
    this.missionType,
    this.soundId = 'default',
  });

  Map<String, dynamic> toFirestore() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'timeTakenSeconds': timeTakenSeconds,
        'missionType': missionType?.name,
        'soundId': soundId,
      };

  factory WakeupSession.fromFirestore(String id, Map<String, dynamic> data) {
    final missionStr = data['missionType'] as String?;
    return WakeupSession(
      id: id,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data['timestamp'] as int?) ?? 0,
      ),
      timeTakenSeconds: (data['timeTakenSeconds'] as int?) ?? 0,
      missionType: missionStr != null ? missionTypeFromString(missionStr) : null,
      soundId: (data['soundId'] as String?) ?? 'default',
    );
  }
}
