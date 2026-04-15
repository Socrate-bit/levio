import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/auth_service.dart';
import '../../missions/models/mission.dart';
import '../cubit/alarm_state.dart';

class AlarmFirestoreService {
  static CollectionReference<Map<String, dynamic>> _col() =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.uid)
          .collection('alarms');

  static Future<void> saveAlarm(AppAlarmEntry entry) => _col().doc(entry.id).set({
        'dateTimeMs': entry.dateTime.millisecondsSinceEpoch,
        'missionType': entry.missionType.name,
        'name': entry.name,
        'soundId': entry.soundId,
        'repeatDays': entry.repeatDays,
        'isEnabled': entry.isEnabled,
        'isOneTime': entry.isOneTime,
        'mathDifficulty': entry.mathDifficulty.name,
        'createdAtMs': entry.createdAt.millisecondsSinceEpoch,
        if (entry.customObject != null) 'customObject': entry.customObject,
      });

  static Future<void> deleteAlarm(String id) => _col().doc(id).delete();

  static Future<AppAlarmEntry?> getAlarm(String id) async {
    final doc = await _col().doc(id).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return AppAlarmEntry(
      id: doc.id,
      dateTime: DateTime.fromMillisecondsSinceEpoch(d['dateTimeMs'] as int),
      missionType: missionTypeFromString(d['missionType'] as String? ?? 'pushUps'),
      name: d['name'] as String? ?? '',
      soundId: d['soundId'] as String? ?? 'default',
      repeatDays: List<bool>.from(
          d['repeatDays'] as List? ?? [false, true, true, true, true, true, false]),
      isEnabled: d['isEnabled'] as bool? ?? true,
      isOneTime: d['isOneTime'] as bool? ?? false,
      mathDifficulty: _mathDifficulty(d['mathDifficulty'] as String?),
      customObject: d['customObject'] as String?,
      createdAt: d['createdAtMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(d['createdAtMs'] as int)
          : null,
    );
  }

  static Future<List<AppAlarmEntry>> getAlarms() async {
    final snap = await _col().get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return AppAlarmEntry(
        id: doc.id,
        dateTime: DateTime.fromMillisecondsSinceEpoch(d['dateTimeMs'] as int),
        missionType: missionTypeFromString(d['missionType'] as String? ?? 'pushUps'),
        name: d['name'] as String? ?? '',
        soundId: d['soundId'] as String? ?? 'default',
        repeatDays: List<bool>.from(
            d['repeatDays'] as List? ?? [false, true, true, true, true, true, false]),
        isEnabled: d['isEnabled'] as bool? ?? true,
        isOneTime: d['isOneTime'] as bool? ?? false,
        mathDifficulty: _mathDifficulty(d['mathDifficulty'] as String?),
        customObject: d['customObject'] as String?,
        createdAt: d['createdAtMs'] != null
            ? DateTime.fromMillisecondsSinceEpoch(d['createdAtMs'] as int)
            : null,
      );
    }).toList();
  }

  static MathDifficulty _mathDifficulty(String? s) => switch (s) {
        'medium' => MathDifficulty.medium,
        'hard' => MathDifficulty.hard,
        _ => MathDifficulty.easy,
      };
}
