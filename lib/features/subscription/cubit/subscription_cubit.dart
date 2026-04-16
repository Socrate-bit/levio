import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import 'subscription_state.dart';

/// Listens to Superwall's subscription status stream and gates alarm
/// scheduling: disables all alarms when inactive, restores them when active.
class SubscriptionCubit extends Cubit<SubscriptionState> {
  final AlarmCubit _alarmCubit;
  final AuthCubit _authCubit;
  StreamSubscription<SubscriptionStatus>? _superwallSub;
  StreamSubscription? _authSub;

  SubscriptionCubit({
    required AlarmCubit alarmCubit,
    required AuthCubit authCubit,
  })  : _alarmCubit = alarmCubit,
        _authCubit = authCubit,
        super(const SubscriptionState()) {
    _init();
  }

  void _init() {
    // Admin/UGC users bypass Superwall entirely
    if (_authCubit.state.skipsPaywall) {
      emit(state.copyWith(status: SubscriptionGateStatus.active));
      return;
    }

    // Listen for auth changes (e.g. referral code redeemed → becomes UGC)
    _authSub = _authCubit.stream.listen((authState) {
      if (authState.skipsPaywall) {
        _superwallSub?.cancel();
        _superwallSub = null;
        _onStatusChanged(state.status, SubscriptionGateStatus.active);
        emit(state.copyWith(status: SubscriptionGateStatus.active));
      }
    });

    // Listen to Superwall subscription status stream
    try {
      _superwallSub =
          Superwall.shared.subscriptionStatus.listen(_handleSuperwall);
    } catch (e) {
      debugPrint('[SubscriptionCubit] subscriptionStatus listen failed: $e');
    }
  }

  void _handleSuperwall(SubscriptionStatus status) {
    // Skip if admin/ugc took over
    if (_authCubit.state.skipsPaywall) return;

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

    final previous = state.status;
    emit(state.copyWith(status: mapped));
    _onStatusChanged(previous, mapped);
  }

  /// Reacts to subscription status transitions.
  void _onStatusChanged(
    SubscriptionGateStatus previous,
    SubscriptionGateStatus next,
  ) {
    if (next == SubscriptionGateStatus.inactive) {
      _alarmCubit.disableAllForSubscription();
    } else if (next == SubscriptionGateStatus.active &&
        previous != SubscriptionGateStatus.unknown) {
      // Restore only when coming from a known inactive state,
      // not on first launch (unknown → active).
      _alarmCubit.restoreSubscriptionDisabled();
    }
  }

  @override
  Future<void> close() {
    _superwallSub?.cancel();
    _authSub?.cancel();
    return super.close();
  }
}
