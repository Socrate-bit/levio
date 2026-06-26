import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/auth_service.dart';
import '../models/screentime_schedule.dart';

/// Resolved screen-time config loaded from Firestore.
typedef ScreenTimeConfig = ({bool enabled, List<ScreenTimeSchedule> schedules});

/// Syncs the screen-time config (master enabled flag + schedules) to Firestore
/// at `users/{uid}/meta/screentime`. The blocked-app selection is NOT synced —
/// FamilyControls tokens are device-specific, so each device picks its own.
class ScreenTimeFirestoreService {
  static DocumentReference<Map<String, dynamic>> _doc() =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.uid)
          .collection('meta')
          .doc('screentime');

  static Future<void> save(
    bool enabled,
    List<ScreenTimeSchedule> schedules,
  ) =>
      _doc().set({
        'enabled': enabled,
        'schedules': schedules.map((s) => s.toJson()).toList(),
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });

  static Future<ScreenTimeConfig?> load() async {
    final doc = await _doc().get();
    if (!doc.exists) return null;
    return _fromData(doc.data()!);
  }

  static ScreenTimeConfig _fromData(Map<String, dynamic> d) {
    final schedules = (d['schedules'] as List?)
            ?.map((s) =>
                ScreenTimeSchedule.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList() ??
        const <ScreenTimeSchedule>[];
    return (enabled: d['enabled'] as bool? ?? false, schedules: schedules);
  }
}
