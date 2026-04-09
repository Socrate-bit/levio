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

  /// Returns up to [limit] sessions ordered newest-first.
  /// If [since] is provided, only returns sessions after that date.
  static Future<List<WakeupSession>> getSessions({
    int limit = 50,
    DateTime? since,
  }) async {
    var query = _sessions
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (since != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: since.millisecondsSinceEpoch,
      );
    }

    final snap = await query.get();
    return snap.docs
        .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
        .toList();
  }

  static Future<List<WakeupSession>> getSessionsThisWeek() async {
    final now = DateTime.now();
    final daysFromSunday = now.weekday % 7;
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - daysFromSunday,
    );
    return getSessions(limit: 100, since: startOfWeek);
  }

  static Future<List<WakeupSession>> getSessionsThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getSessions(limit: 200, since: startOfMonth);
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
