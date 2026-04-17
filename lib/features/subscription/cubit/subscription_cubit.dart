import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../../services/auth_service.dart';
import '../../../services/referral_service.dart';
import 'subscription_state.dart';

/// Owns subscription gate state (Superwall stream) plus user type / referral
/// logic. Determines whether the user can access gated features via [hasAccess].
class SubscriptionCubit extends Cubit<SubscriptionState> {
  StreamSubscription<SubscriptionStatus>? _superwallSub;

  SubscriptionCubit() : super(const SubscriptionState()) {
    _listenSuperwall();
  }

  void _listenSuperwall() {
    try {
      _superwallSub = Superwall.shared.subscriptionStatus.listen(
        _handleSuperwall,
      );
    } catch (e) {
      debugPrint('[SubscriptionCubit] subscriptionStatus listen failed: $e');
    }
  }

  void _handleSuperwall(SubscriptionStatus status) {
    final SubscriptionGateStatus mapped;
    switch (status) {
      case SubscriptionStatusActive():
        mapped = SubscriptionGateStatus.active;
      case SubscriptionStatusInactive():
        mapped = SubscriptionGateStatus.inactive;
      case SubscriptionStatusUnknown():
        mapped = SubscriptionGateStatus.unknown;
    }

    if (mapped == state.status) return;
    emit(state.copyWith(status: mapped));
  }

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
      debugPrint('[SubscriptionCubit] loadUserType failed: $e');
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
      final userType = await ReferralService.redeemCode(code.trim());
      emit(state.copyWith(
        userType: userTypeFromString(userType),
        redeemStatus: ReferralRedeemStatus.success,
      ));
    } catch (e) {
      debugPrint('[SubscriptionCubit] redeemReferralCode failed: $e');
      emit(state.copyWith(redeemStatus: ReferralRedeemStatus.error));
    }
  }

  void clearRedeemStatus() {
    emit(state.copyWith(redeemStatus: ReferralRedeemStatus.idle));
  }

  @override
  Future<void> close() {
    _superwallSub?.cancel();
    return super.close();
  }
}
