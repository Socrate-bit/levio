import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../alarms/services/alarm_readiness_guard.dart';
import '../../alarms/services/alarm_service.dart';
import '../cubit/subscription_cubit.dart';
import '../cubit/subscription_state.dart';
import '../../../shared/bottom_nav_shell.dart';

/// Subscription gate. Loads user_type once, drives [AlarmCubit.sync] only
/// when the user has access, and renders BottomNavShell — wrapped in a
/// paywall overlay when access is missing.
class AppGateWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AppGateWrapper({super.key, required this.navigatorKey});

  @override
  State<AppGateWrapper> createState() => _AppGateWrapperState();
}

class _AppGateWrapperState extends State<AppGateWrapper> {
  /// Whether the device can run Levio alarms (supported iOS + authorization).
  /// While false, a tap-catching overlay re-pops the readiness dialog on every
  /// tap until the user resolves it. Assumed ready until proven otherwise.
  bool _alarmReady = true;

  /// Guards against stacking the readiness dialog on rapid taps.
  bool _readinessDialogOpen = false;

  @override
  void initState() {
    super.initState();
    AlarmService.listenForRing(
      widget.navigatorKey,
      canDismiss: () => context.read<SubscriptionCubit>().state.hasAccess,
      onRingBlocked: () => Superwall.shared.registerPlacement('app_start'),
    );
    // Reconcile once on mount if access is already known (the BlocListener only
    // fires on an access *change*, so it misses the "already true/false at first
    // build" case). Defer past build so cubits are settled before we trigger
    // work. These side effects must NOT run from build() — they reschedule
    // alarms and would duplicate them on every rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyAccess(context.read<SubscriptionCubit>().state.hasAccess);
    });
  }

  /// Runs the access-gated alarm reconciliation for the given access state.
  /// Called from the mount postFrame callback and the access-change listener —
  /// never from build(), because these methods reschedule alarms and firing
  /// them on every rebuild duplicates them.
  void _applyAccess(bool hasAccess) {
    if (!mounted) return;
    final alarmCubit = context.read<AlarmCubit>();
    if (hasAccess) {
      alarmCubit.restoreSubscriptionDisabled();
      alarmCubit.sync();
      _checkAlarmReadiness();
    } else {
      alarmCubit.disableAllForSubscription();
      Superwall.shared.registerPlacement('app_start');
    }
  }

  /// Surfaces the OS-update / alarm-permission dialog while the device isn't
  /// ready, then reflects the (re-evaluated) readiness into [_alarmReady] so
  /// the gating overlay shows/hides accordingly. No-op if already showing.
  Future<void> _checkAlarmReadiness() async {
    if (_readinessDialogOpen || !mounted) return;
    _readinessDialogOpen = true;
    await AlarmReadinessGuard.ensure(context);
    _readinessDialogOpen = false;
    if (!mounted) return;
    final ready = await AlarmReadinessGuard.isReady();
    if (mounted) setState(() => _alarmReady = ready);
  }

  @override
  void dispose() {
    AlarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SubscriptionCubit, SubscriptionState>(
      listenWhen: (prev, curr) => prev.hasAccess != curr.hasAccess,
      listener: (context, sub) => _applyAccess(sub.hasAccess),
      child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, sub) {
          return BlocBuilder<AlarmCubit, AlarmState>(
            builder: (context, alarm) {
              final subReady =
                  sub.isLoaded && sub.status != SubscriptionGateStatus.unknown;
              if (!subReady) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // build() stays pure — alarm reconciliation (restore/disable/sync)
              // is driven by _applyAccess from the mount callback and the
              // access-change listener, never from here. Alarm sync runs in the
              // background — never block the home page with a spinner. Alarms are
              // already loaded via loadAlarm() on auth, and the UI updates
              // reactively when sync re-emits.
              if (sub.hasAccess) {
                if (_alarmReady) return const BottomNavShell();
                // Device can't run alarms (old iOS / no permission): gate the
                // app and re-pop the readiness dialog on every tap.
                return Stack(
                  children: [
                    const BottomNavShell(),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _checkAlarmReadiness,
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  const BottomNavShell(),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          Superwall.shared.registerPlacement('app_start'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
