import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/auth_service.dart';
import '../../../services/referral_service.dart';
import 'auth_state.dart';

/// Holds the current user's type (admin / ugc / normal).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  /// Load user_type from users/{uid} document.
  Future<void> loadUserType() async {
    final uid = AuthService.uidOrNull;
    if (uid == null) {
      emit(state.copyWith(isLoaded: true));
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final typeStr = doc.data()?['user_type'] as String?;
      emit(state.copyWith(
        userType: userTypeFromString(typeStr),
        isLoaded: true,
      ));
    } catch (e) {
      debugPrint('[AuthCubit] loadUserType failed: $e');
      emit(state.copyWith(isLoaded: true));
    }
  }

  /// Redeem a referral code via Cloud Function.
  Future<void> redeemReferralCode(String code) async {
    if (code.trim().isEmpty) return;
    emit(state.copyWith(redeemStatus: ReferralRedeemStatus.submitting));
    try {
      final validType = await ReferralService.validateCode(code.trim());
      if (validType == null) {
        emit(state.copyWith(redeemStatus: ReferralRedeemStatus.invalid));
        return;
      }
      if (validType == 'exhausted') {
        emit(state.copyWith(redeemStatus: ReferralRedeemStatus.exhausted));
        return;
      }
      // Atomic server-side redemption
      final userType = await ReferralService.redeemCode(code.trim());
      emit(state.copyWith(
        userType: userTypeFromString(userType),
        redeemStatus: ReferralRedeemStatus.success,
      ));
    } catch (e) {
      debugPrint('[AuthCubit] redeemReferralCode failed: $e');
      emit(state.copyWith(redeemStatus: ReferralRedeemStatus.error));
    }
  }

  void clearRedeemStatus() {
    emit(state.copyWith(redeemStatus: ReferralRedeemStatus.idle));
  }
}
