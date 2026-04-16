import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../alarms/cubit/alarm_cubit.dart';
import '../alarms/services/alarm_service.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import '../subscription/cubit/subscription_cubit.dart';
import '../subscription/cubit/subscription_state.dart';
import '../../shared/widgets/bottom_nav_shell.dart';

/// Gates content behind auth + subscription loading.
/// Shows a spinner until both resolve, then renders [_MainContent].
class MainAppGate extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MainAppGate({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, subState) {
            // If auth skips paywall, override subscription to active
            if (authState.isLoaded && authState.skipsPaywall) {
              context.read<SubscriptionCubit>().setActive();
            }

            final loaded = authState.isLoaded &&
                subState.status != SubscriptionGateStatus.unknown;

            if (!loaded) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasAccess = authState.skipsPaywall || subState.isActive;

            return _MainContent(
              navigatorKey: navigatorKey,
              hasAccess: hasAccess,
            );
          },
        );
      },
    );
  }
}

/// Manages alarm ring listener and renders content with optional paywall
/// overlay. Enables/disables alarms based on access.
class _MainContent extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool hasAccess;

  const _MainContent({
    required this.navigatorKey,
    required this.hasAccess,
  });

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent> {
  @override
  void initState() {
    super.initState();
    AlarmService.listenForRing(
      widget.navigatorKey,
      canDismiss: () => widget.hasAccess,
      onRingBlocked: () =>
          Superwall.shared.registerPlacement('app_start'),
    );
  }

  @override
  void didUpdateWidget(covariant _MainContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasAccess != widget.hasAccess) {
      AlarmService.listenForRing(
        widget.navigatorKey,
        canDismiss: () => widget.hasAccess,
        onRingBlocked: () =>
            Superwall.shared.registerPlacement('app_start'),
      );
    }
  }

  @override
  void dispose() {
    AlarmService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarmCubit = context.read<AlarmCubit>();

    if (widget.hasAccess) {
      alarmCubit.restoreSubscriptionDisabled();
      return const BottomNavShell();
    }

    alarmCubit.disableAllForSubscription();
    return Stack(
      children: [
        const BottomNavShell(),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Superwall.shared.registerPlacement('app_start'),
          ),
        ),
      ],
    );
  }
}
