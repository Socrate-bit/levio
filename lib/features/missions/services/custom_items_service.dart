import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/auth_service.dart';
import '../../subscription/services/analytics_service.dart';

/// Persists user-created custom objects and affirmations in Firestore.
///
/// Document: `users/{uid}/meta/custom`
/// Fields: `objects` (list of strings), `objectEmojis` (map of name -> emoji),
/// `affirmations` (list of strings)
class CustomItemsService {
  static DocumentReference<Map<String, dynamic>> _doc() =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.uid)
          .collection('meta')
          .doc('custom');

  // ── Affirmations ──

  static Future<List<String>> getCustomAffirmations() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists) return [];
      return List<String>.from(snap.data()?['affirmations'] ?? []);
    } catch (e, st) {
      debugPrint('[CustomItemsService] getCustomAffirmations error: $e');
      AnalyticsService.trackError('CustomItemsService.getCustomAffirmations', e, st);
      return [];
    }
  }

  static Future<void> addCustomAffirmation(String text) async {
    try {
      await _doc().set({
        'affirmations': FieldValue.arrayUnion([text]),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[CustomItemsService] addCustomAffirmation error: $e');
      AnalyticsService.trackError('CustomItemsService.addCustomAffirmation', e, st);
    }
  }

  static Future<void> removeCustomAffirmation(String text) async {
    try {
      await _doc().set({
        'affirmations': FieldValue.arrayRemove([text]),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[CustomItemsService] removeCustomAffirmation error: $e');
      AnalyticsService.trackError('CustomItemsService.removeCustomAffirmation', e, st);
    }
  }

  // ── Objects ──

  static Future<List<String>> getCustomObjects() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists) return [];
      return List<String>.from(snap.data()?['objects'] ?? []);
    } catch (e, st) {
      debugPrint('[CustomItemsService] getCustomObjects error: $e');
      AnalyticsService.trackError('CustomItemsService.getCustomObjects', e, st);
      return [];
    }
  }

  /// Returns a map of custom-object name -> emoji. Names without a stored
  /// emoji are simply absent from the map (callers fall back to a default).
  static Future<Map<String, String>> getCustomObjectEmojis() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists) return {};
      final raw = snap.data()?['objectEmojis'];
      if (raw is Map) return Map<String, String>.from(raw);
      return {};
    } catch (e, st) {
      debugPrint('[CustomItemsService] getCustomObjectEmojis error: $e');
      AnalyticsService.trackError(
          'CustomItemsService.getCustomObjectEmojis', e, st);
      return {};
    }
  }

  static Future<void> addCustomObject(String text, {String? emoji}) async {
    try {
      await _doc().set({
        'objects': FieldValue.arrayUnion([text]),
        if (emoji != null && emoji.isNotEmpty)
          'objectEmojis': {text: emoji},
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[CustomItemsService] addCustomObject error: $e');
      AnalyticsService.trackError('CustomItemsService.addCustomObject', e, st);
    }
  }

  static Future<void> removeCustomObject(String text) async {
    try {
      await _doc().set({
        'objects': FieldValue.arrayRemove([text]),
      }, SetOptions(merge: true));
      // Drop the parallel emoji entry for this object. Use a FieldPath list so
      // the name is matched literally — a String key would be split on '.',
      // mis-targeting names that contain a dot (e.g. "Mr. Coffee").
      await _doc().update({
        FieldPath(['objectEmojis', text]): FieldValue.delete(),
      });
    } catch (e, st) {
      debugPrint('[CustomItemsService] removeCustomObject error: $e');
      AnalyticsService.trackError('CustomItemsService.removeCustomObject', e, st);
    }
  }

  // ── Routine steps ──

  static Future<List<String>> getCustomRoutineSteps() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists) return [];
      return List<String>.from(snap.data()?['routineSteps'] ?? []);
    } catch (e, st) {
      debugPrint('[CustomItemsService] getCustomRoutineSteps error: $e');
      AnalyticsService.trackError('CustomItemsService.getCustomRoutineSteps', e, st);
      return [];
    }
  }

  static Future<void> addCustomRoutineStep(String text) async {
    try {
      await _doc().set({
        'routineSteps': FieldValue.arrayUnion([text]),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('[CustomItemsService] addCustomRoutineStep error: $e');
      AnalyticsService.trackError('CustomItemsService.addCustomRoutineStep', e, st);
    }
  }
}
