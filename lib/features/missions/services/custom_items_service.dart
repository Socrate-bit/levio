import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../auth/auth_service.dart';

/// Persists user-created custom objects and affirmations in Firestore.
///
/// Document: `users/{uid}/meta/custom`
/// Fields: `objects` (list of strings), `affirmations` (list of strings)
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
    } catch (e) {
      debugPrint('[CustomItemsService] getCustomAffirmations error: $e');
      return [];
    }
  }

  static Future<void> addCustomAffirmation(String text) async {
    try {
      await _doc().set({
        'affirmations': FieldValue.arrayUnion([text]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CustomItemsService] addCustomAffirmation error: $e');
    }
  }

  static Future<void> removeCustomAffirmation(String text) async {
    try {
      await _doc().set({
        'affirmations': FieldValue.arrayRemove([text]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CustomItemsService] removeCustomAffirmation error: $e');
    }
  }

  // ── Objects ──

  static Future<List<String>> getCustomObjects() async {
    try {
      final snap = await _doc().get();
      if (!snap.exists) return [];
      return List<String>.from(snap.data()?['objects'] ?? []);
    } catch (e) {
      debugPrint('[CustomItemsService] getCustomObjects error: $e');
      return [];
    }
  }

  static Future<void> addCustomObject(String text) async {
    try {
      await _doc().set({
        'objects': FieldValue.arrayUnion([text]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CustomItemsService] addCustomObject error: $e');
    }
  }

  static Future<void> removeCustomObject(String text) async {
    try {
      await _doc().set({
        'objects': FieldValue.arrayRemove([text]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CustomItemsService] removeCustomObject error: $e');
    }
  }
}
