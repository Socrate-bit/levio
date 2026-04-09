import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/auth_service.dart';
import '../models/wakeup_session.dart';

class HistoryService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('users').doc(AuthService.uid).collection('sessions');

  static DocumentReference<Map<String, dynamic>> get _profile =>
      _db.collection('users').doc(AuthService.uid).collection('meta').doc('profile');

  static Future<void> saveSession(WakeupSession session) async {
    await _sessions.doc(session.id).set(session.toFirestore());
    await _profile.set(
      {'totalWakeups': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  static Future<List<WakeupSession>> getSessions({int limit = 50}) async {
    final snap = await _sessions
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
        .toList();
  }

  static Future<List<WakeupSession>> getSessionsThisWeek() async {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday % 7)).copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
            );
    final snap = await _sessions
        .where('timestamp',
            isGreaterThanOrEqualTo: startOfWeek.millisecondsSinceEpoch)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
        .toList();
  }

  static Future<int> getTotalWakeups() async {
    final doc = await _profile.get();
    if (!doc.exists) return 0;
    return (doc.data()?['totalWakeups'] as int?) ?? 0;
  }

  static Future<WakeupSession?> getLastSession() async {
    final sessions = await getSessions(limit: 1);
    return sessions.isEmpty ? null : sessions.first;
  }
}
