import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import 'subscription_state.dart';

/// Pure subscription state holder — listens to Superwall's subscription status
/// stream and emits [SubscriptionGateStatus]. No dependencies on other cubits.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  StreamSubscription<SubscriptionStatus>? _superwallSub;

  SubscriptionCubit() : super(const SubscriptionState()) {
    _listenSuperwall();
  }

  /// Manually set the subscription gate (e.g. when auth determines user
  /// skips paywall).
  void setActive() => emit(state.copyWith(status: SubscriptionGateStatus.active));

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

  @override
  Future<void> close() {
    _superwallSub?.cancel();
    return super.close();
  }
}
