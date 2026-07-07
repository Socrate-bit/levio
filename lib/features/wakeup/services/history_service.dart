import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/auth_service.dart';
import '../../subscription/services/analytics_service.dart';
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
    bool isSleep = false,
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
      isSleep: isSleep,
    );
    final docId = now.millisecondsSinceEpoch.toString();
    await _sessions.doc(docId).set(session.toFirestore());
    AnalyticsService.capture(AnalyticsService.alarmRingStarted, {
      'alarm_id': alarmId,
      'mission_type': missionType?.name ?? 'none',
      'sound_id': soundId,
      'alarm_type': isSleep ? 'sleep' : 'wakeup',
    });
    return docId;
  }

  /// Marks a pending session as completed and records how long it took.
  static Future<void> completeSession(
    String sessionId, {
    required int timeTakenSeconds,
    MissionType? missionType,
  }) async {
    await _sessions.doc(sessionId).update({
      'completed': true,
      'timeTakenSeconds': timeTakenSeconds,
    });
    await _profile.set(
      {'totalWakeups': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    final props = <String, Object>{
      'time_taken_seconds': timeTakenSeconds,
      'mission_type': missionType?.name ?? 'none',
      'completed': true,
    };
    AnalyticsService.capture(AnalyticsService.alarmRingDismissed, props);
    AnalyticsService.capture(AnalyticsService.sessionSaved, props);
    if (missionType != null && missionType != MissionType.none) {
      AnalyticsService.capture(AnalyticsService.missionCompleted, {
        'type': missionType.name,
        'duration_ms': timeTakenSeconds * 1000,
      });
    }
  }

  /// Records an alarm that was silently swept because another alarm ringing at
  /// the same time had its mission completed. Marked completed so it doesn't
  /// linger as pending, and flagged `autoDismissed` so it doesn't increment
  /// totalWakeups. Reuses the alarm's existing pending session if one exists.
  static Future<void> recordAutoDismissedSession({
    required String alarmId,
    MissionType? missionType,
    String soundId = 'default',
  }) async {
    final pending = await getPendingSession(alarmId);
    if (pending != null) {
      await _sessions.doc(pending.id).update({
        'completed': true,
        'autoDismissed': true,
      });
    } else {
      final now = DateTime.now();
      final session = WakeupSession(
        id: '',
        alarmId: alarmId,
        timestamp: now,
        timeTakenSeconds: 0,
        missionType: missionType,
        soundId: soundId,
        completed: true,
        autoDismissed: true,
      );
      await _sessions.doc(now.millisecondsSinceEpoch.toString()).set(
            session.toFirestore(),
          );
    }
    AnalyticsService.capture(AnalyticsService.alarmRingDismissed, {
      'alarm_id': alarmId,
      'mission_type': missionType?.name ?? 'none',
      'completed': true,
      'auto_dismissed': true,
    });
  }

  /// Records the user deactivating screen-time blocking (unlocking the controls
  /// during an active window). Stored as an incomplete, alarm-less session
  /// flagged `screenTimeDisabled` so it shows its own distinct history entry and
  /// counts as a missed day for the streak. Does not increment totalWakeups.
  static Future<String> recordScreenTimeDisabledSession() async {
    final now = DateTime.now();
    final session = WakeupSession(
      id: '',
      alarmId: null,
      timestamp: now,
      timeTakenSeconds: 0,
      completed: false,
      screenTimeDisabled: true,
    );
    final docId = now.millisecondsSinceEpoch.toString();
    await _sessions.doc(docId).set(session.toFirestore());
    return docId;
  }

  /// Creates a missed session (completed: false) for an alarm that was never dismissed.
  static Future<String> createMissedSession({
    required String alarmId,
    MissionType? missionType,
    String soundId = 'default',
    required DateTime timestamp,
    bool isSleep = false,
  }) async {
    final session = WakeupSession(
      id: '',
      alarmId: alarmId,
      timestamp: timestamp,
      timeTakenSeconds: 0,
      missionType: missionType,
      soundId: soundId,
      completed: false,
      isSleep: isSleep,
    );
    final docId = timestamp.millisecondsSinceEpoch.toString();
    await _sessions.doc(docId).set(session.toFirestore());
    AnalyticsService.capture(AnalyticsService.sessionSaved, {
      'alarm_id': alarmId,
      'mission_type': missionType?.name ?? 'none',
      'completed': false,
    });
    return docId;
  }

  /// Returns up to [limit] sessions ordered newest-first.
  /// By default only returns completed sessions. Pass [includeIncomplete: true]
  /// to include pending/missed sessions.
  ///
  /// Auto-dismissed sessions (alarms silently swept by another alarm's mission)
  /// are excluded by default so they never reach stats. Pass
  /// [includeAutoDismissed: true] for the history log or the missed-alarm check.
  static Future<List<WakeupSession>> getSessions({
    int limit = 50,
    DateTime? since,
    bool includeIncomplete = false,
    bool includeAutoDismissed = false,
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
    var sessions = snap.docs
        .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
        .toList();

    if (!includeAutoDismissed) {
      sessions = sessions.where((s) => !s.autoDismissed).toList();
    }
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

  /// Records that the Spin to Win wheel was used today for [alarmId].
  /// Finds the most recent session for the alarm today and sets spinToWinUsed.
  static Future<void> markSpinToWinUsed(String alarmId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snap = await _sessions
        .where('alarmId', isEqualTo: alarmId)
        .where('timestamp',
            isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.update({'spinToWinUsed': true});
  }

  /// Returns true if the Spin to Win wheel has already been used today.
  static Future<bool> hasSpinToWinUsedToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final sessions = await getSessions(
      limit: 50,
      since: startOfDay,
      includeIncomplete: true,
    );
    return sessions.any((s) => s.spinToWinUsed);
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

  /// Real-time stream of sessions, newest-first. Excludes auto-dismissed
  /// sessions so the stats screens (insights, home) never count them.
  static Stream<List<WakeupSession>> watchSessions({int limit = 500}) {
    return _sessions
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WakeupSession.fromFirestore(d.id, d.data()))
            .where((s) => !s.autoDismissed)
            .toList());
  }
}
