import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Handles referral code validation and redemption.
class ReferralService {
  static final _firestore = FirebaseFirestore.instance;
  static final _functions = FirebaseFunctions.instance;

  /// Client-side pre-validation. Returns the code's type string if valid,
  /// 'exhausted' if num_use >= max_use, or null if invalid/missing fields.
  static Future<String?> validateCode(String code) async {
    try {
      final doc =
          await _firestore.collection('referralCodes').doc(code).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final type = data['type'] as String?;
      final numUse = data['num_use'] as int?;
      final maxUse = data['max_use'] as int?;
      // All required fields must be present
      if (type == null || numUse == null || maxUse == null) return null;
      if (numUse >= maxUse) return 'exhausted';
      return type;
    } catch (e, st) {
      debugPrint('[ReferralService] validateCode failed: $e');
      AnalyticsService.trackError('ReferralService.validateCode', e, st);
      return null;
    }
  }

  /// Calls the redeemReferralCode callable Cloud Function.
  /// Returns the user_type string on success.
  static Future<String> redeemCode(String code) async {
    final callable = _functions.httpsCallable('redeemReferralCode');
    final result = await callable.call<Map<String, dynamic>>({'code': code});
    return result.data['user_type'] as String;
  }
}
