import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/auth_service.dart';
import '../../missions/models/mission.dart';
import '../models/wakeup_session.dart';

class HistoryService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _sessions =>
      _db.collection('users').doc(AuthService.uid).collection('sessions');

  static DocumentReference<Map<String, dynamic>> get _profile =>
      _db.collection('users').doc(AuthService.uid).collection('meta').doc('profile');

  /// Creates a pending (not yet completed) session when an alarm fires.
  /// Returns the new session document ID.
  static Future<String> createPendingSession({
    required String alarmId,
    MissionType? missionType,
    String soundId = 'default',
  }) async {
    final now = DateTime.now();
    final session = WakeupSession(
      id: '',
      alarmId: alarmId,
      timestamp: now,
      timeTakenSeconds: 0,
      missionType: missionType,
      soundId: soundId,
      completed: false,
    );
    final docId = now.millisecondsSinceEpoch.toString();
    await _sessions.doc(docId).set(session.toFirestore());
    return docId;
  }

  /// Marks a pending session as completed and records how long it took.
  static Future<void> completeSession(
    String sessionId, {
    required int timeTakenSeconds,
  }) async {
    await _sessions.doc(sessionId).update({
      'completed': true,
      'timeTakenSeconds': timeTakenSeconds,
    });
    await _profile.set(
      {'totalWakeups': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  /// Creates a missed session (completed: false) for an alarm that was never dismissed.
  static Future<String> createMissedSession({
    required String alarmId,
    MissionType? missionType,
    String soundId = 'default',
    required DateTime timestamp,
  }) async {
    final session = WakeupSession(
      id: '',
      alarmId: alarmId,
      timestamp: timestamp,
      timeTakenSeconds: 0,
      missionType: missionType,
      soundId: soundId,
      completed: false,
    );
    final docId = timestamp.millisecondsSinceEpoch.toString();
    await _sessions.doc(docId).set(session.toFirestore());
    return docId;
  }

  /// Returns up to [limit] sessions ordered newest-first.
  /// By default only returns completed sessions. Pass [includeIncomplete: true]
  /// to include pending/missed sessions.
  static Future<List<WakeupSession>> getSessions({
    int limit = 50,
    DateTime? since,
    bool includeIncomplete = false,
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
    final sessions = snap.docs
        .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
        .toList();

    if (!includeIncomplete) {
      return sessions.where((s) => s.completed).toList();
    }
    return sessions;
  }

  /// Returns sessions in the current week (Mon–Sun), both completed and incomplete.
  static Future<List<WakeupSession>> getSessionsThisWeek() async {
    final now = DateTime.now();
    // weekday: Mon=1 … Sun=7
    final daysFromMonday = now.weekday - 1;
    final startOfWeek = DateTime(now.year, now.month, now.day - daysFromMonday);
    return getSessions(limit: 100, since: startOfWeek, includeIncomplete: true);
  }

  static Future<List<WakeupSession>> getSessionsThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getSessions(limit: 200, since: startOfMonth, includeIncomplete: true);
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

  /// Returns the most recent pending (incomplete) session for the given alarm,
  /// or null if none exists.
  static Future<WakeupSession?> getPendingSession(String alarmId) async {
    final snap = await _sessions
        .where('alarmId', isEqualTo: alarmId)
        .where('completed', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return WakeupSession.fromFirestore(doc.id, doc.data());
  }

  /// Real-time stream of completed sessions, newest-first.
  static Stream<List<WakeupSession>> watchSessions({int limit = 500}) {
    return _sessions
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
            .where((s) => s.completed)
            .toList());
  }
}
