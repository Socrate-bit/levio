import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/referral_service.dart';
import 'subscription_state.dart';

/// Owns subscription gate state (Superwall stream) plus user type / referral
/// logic. Determines whether the user can access gated features via [hasAccess].
class SubscriptionCubit extends Cubit<SubscriptionState> {
  StreamSubscription<SubscriptionStatus>? _superwallSub;
  String? _lastIdentifiedUid;

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

    final wasActive = state.isActive;
    emit(state.copyWith(status: mapped));

    if (!wasActive && mapped == SubscriptionGateStatus.active) {
      AnalyticsService.capture(AnalyticsService.subscriptionActivated);
    } else if (wasActive && mapped == SubscriptionGateStatus.inactive) {
      AnalyticsService.capture(AnalyticsService.subscriptionLost);
    }
  }

  /// Identify user in Superwall + PostHog; load user_type + ensure
  /// superwallId exists in users/{uid} doc. Idempotent across rebuilds.
  Future<void> identifyUser(String uid) async {
    if (_lastIdentifiedUid == uid) return;
    _lastIdentifiedUid = uid;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      final data = doc.data() ?? const <String, dynamic>{};

      final typeStr = data['user_type'] as String?;
      var superwallId = data['superwallId'] as String?;
      if (superwallId == null || superwallId.isEmpty) {
        superwallId = const Uuid().v4();
        await docRef.set(
          {'superwallId': superwallId},
          SetOptions(merge: true),
        );
      }

      try {
        await Superwall.shared.identify(superwallId);
      } catch (e) {
        debugPrint('[SubscriptionCubit] Superwall.identify failed: $e');
      }
      await AnalyticsService.identify(uid);

      emit(state.copyWith(
        userType: userTypeFromString(typeStr),
        isLoaded: true,
      ));
    } catch (e) {
      debugPrint('[SubscriptionCubit] identifyUser failed: $e');
      emit(state.copyWith(isLoaded: true));
    }
  }

  /// Re-reads user_type from Firestore (e.g. after referral redemption). Does
  /// not re-identify Superwall/PostHog.
  Future<void> refreshUserType() async {
    final uid = AuthService.uidOrNull;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final typeStr = doc.data()?['user_type'] as String?;
      emit(state.copyWith(userType: userTypeFromString(typeStr)));
    } catch (e) {
      debugPrint('[SubscriptionCubit] refreshUserType failed: $e');
    }
  }

  /// Reset Superwall + PostHog identity on logout.
  Future<void> resetIdentity() async {
    try {
      await Superwall.shared.reset();
    } catch (e) {
      debugPrint('[SubscriptionCubit] Superwall.reset failed: $e');
    }
    await AnalyticsService.reset();
    _lastIdentifiedUid = null;
    emit(const SubscriptionState());
  }

  /// Redeem a referral code via Cloud Function.
  Future<void> redeemReferralCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    emit(state.copyWith(redeemStatus: ReferralRedeemStatus.submitting));
    AnalyticsService.capture(AnalyticsService.referralRedeemAttempt);
    try {
      final validType = await ReferralService.validateCode(trimmed);
      if (validType == null) {
        emit(state.copyWith(redeemStatus: ReferralRedeemStatus.invalid));
        AnalyticsService.capture(
          AnalyticsService.referralRedeemFailed,
          {'reason': 'invalid'},
        );
        return;
      }
      if (validType == 'exhausted') {
        emit(state.copyWith(redeemStatus: ReferralRedeemStatus.exhausted));
        AnalyticsService.capture(
          AnalyticsService.referralRedeemFailed,
          {'reason': 'exhausted'},
        );
        return;
      }
      final userType = await ReferralService.redeemCode(trimmed);
      emit(state.copyWith(
        userType: userTypeFromString(userType),
        redeemStatus: ReferralRedeemStatus.success,
      ));
      AnalyticsService.capture(
        AnalyticsService.referralRedeemSuccess,
        {'user_type': userType},
      );
    } catch (e) {
      debugPrint('[SubscriptionCubit] redeemReferralCode failed: $e');
      emit(state.copyWith(redeemStatus: ReferralRedeemStatus.error));
      AnalyticsService.capture(
        AnalyticsService.referralRedeemFailed,
        {'reason': 'error'},
      );
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
