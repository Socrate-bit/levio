import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/cubit/alarm_state.dart';
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
  @override
  void initState() {
    super.initState();
    AlarmService.listenForRing(
      widget.navigatorKey,
      canDismiss: () => context.read<SubscriptionCubit>().state.hasAccess,
      onRingBlocked: () =>
          Superwall.shared.registerPlacement('app_start'),
    );
    // Sync once on mount if access is already known. Defer past build so
    // cubits are settled before we trigger work.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<SubscriptionCubit>().state.hasAccess) {
        context.read<AlarmCubit>().sync();
      }
    });
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
      listener: (context, sub) {
        final alarmCubit = context.read<AlarmCubit>();
        if (sub.hasAccess) {
          alarmCubit.restoreSubscriptionDisabled();
          alarmCubit.sync();
        } else {
          alarmCubit.disableAllForSubscription();
        }
      },
      child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, sub) {
          return BlocBuilder<AlarmCubit, AlarmState>(
            builder: (context, alarm) {
              final subReady = sub.isLoaded &&
                  sub.status != SubscriptionGateStatus.unknown;
              if (!subReady) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              // Only show alarm spinner when we actually triggered a sync.
              if (sub.hasAccess && alarm.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (sub.hasAccess) {
                return const BottomNavShell();
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
