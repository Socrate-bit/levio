import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/auth_service.dart';
import '../../missions/models/mission_config.dart';
import '../cubit/alarm_state.dart';

class AlarmFirestoreService {
  static CollectionReference<Map<String, dynamic>> _col() =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.uid)
          .collection('alarms');

  static Future<void> saveAlarm(AppAlarmEntry entry) => _col().doc(entry.id).set({
        'dateTimeMs': entry.dateTime.millisecondsSinceEpoch,
        'missions': entry.missions.map((m) => m.toMap()).toList(),
        'name': entry.name,
        'soundId': entry.soundId,
        'repeatDays': entry.repeatDays,
        'isEnabled': entry.isEnabled,
        'isOneTime': entry.isOneTime,
        'disabledBySubscription': entry.disabledBySubscription,
        'isSleep': entry.isSleep,
        'gentle': entry.gentle,
        'reminderEnabled': entry.reminderEnabled,
        'reminderMinutesBefore': entry.reminderMinutesBefore,
        'createdAtMs': entry.createdAt.millisecondsSinceEpoch,
      });

  static Future<void> deleteAlarm(String id) => _col().doc(id).delete();

  static Future<AppAlarmEntry?> getAlarm(String id) async {
    final doc = await _col().doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  static Future<List<AppAlarmEntry>> getAlarms() async {
    final snap = await _col().get();
    return snap.docs.map(_fromDoc).toList();
  }

  static AppAlarmEntry _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppAlarmEntry(
      id: doc.id,
      dateTime: DateTime.fromMillisecondsSinceEpoch(d['dateTimeMs'] as int),
      missions: (d['missions'] as List?)
              ?.map((m) => MissionConfig.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          const [],
      name: d['name'] as String? ?? '',
      soundId: d['soundId'] as String? ?? 'default',
      repeatDays: List<bool>.from(
          d['repeatDays'] as List? ?? [false, true, true, true, true, true, false]),
      isEnabled: d['isEnabled'] as bool? ?? true,
      isOneTime: d['isOneTime'] as bool? ?? false,
      disabledBySubscription: d['disabledBySubscription'] as bool? ?? false,
      isSleep: d['isSleep'] as bool? ?? false,
      gentle: d['gentle'] as bool? ?? false,
      reminderEnabled: d['reminderEnabled'] as bool? ?? false,
      reminderMinutesBefore: d['reminderMinutesBefore'] as int? ?? 15,
      createdAt: d['createdAtMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(d['createdAtMs'] as int)
          : null,
    );
  }
}
