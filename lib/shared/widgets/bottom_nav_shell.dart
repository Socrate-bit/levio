import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/haptic_utils.dart';
import 'package:levio/features/auth/cubit/auth_cubit.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/services/superwall_service.dart';

import '../../features/alarms/screens/alarms_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class BottomNavShell extends StatefulWidget {
  final int initialIndex;
  const BottomNavShell({super.key, this.initialIndex = 0});

  @override
  State<BottomNavShell> createState() => BottomNavShellState();

  static BottomNavShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<BottomNavShellState>();
}

class BottomNavShellState extends State<BottomNavShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void navigateTo(int index) {
    setState(() => _index = index);
  }

  static const _tabs = [
    HomeScreen(),
    AlarmsScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState.isLoaded) {
      SuperwallService.registerAppStart(skipPaywall: authState.skipsPaywall);
    }
    final l10n = AppLocalizations.of(context);
    final bool isIOS26 = PlatformInfo.isIOS26OrHigher();
    final bool isIOS = PlatformInfo.isIOS;

    return AdaptiveScaffold(
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        useNativeBottomBar: true,
        selectedIndex: _index,
        onTap: withHapticValue((i) => setState(() => _index = i)),
        items: [
          AdaptiveNavigationDestination(
            icon: isIOS26
                ? 'house'
                : isIOS
                ? CupertinoIcons.home
                : Icons.home_outlined,
            selectedIcon: isIOS26
                ? 'house.fill'
                : isIOS
                ? CupertinoIcons.home
                : Icons.home,
            label: l10n.navHome,
          ),
          AdaptiveNavigationDestination(
            icon: isIOS26
                ? 'alarm'
                : isIOS
                ? CupertinoIcons.alarm
                : Icons.alarm_outlined,
            selectedIcon: isIOS26
                ? 'alarm.fill'
                : isIOS
                ? CupertinoIcons.alarm
                : Icons.alarm,
            label: l10n.navAlarms,
          ),
          AdaptiveNavigationDestination(
            icon: isIOS26
                ? 'chart.bar'
                : isIOS
                ? CupertinoIcons.chart_bar
                : Icons.bar_chart_outlined,
            selectedIcon: isIOS26
                ? 'chart.bar.fill'
                : isIOS
                ? CupertinoIcons.chart_bar_fill
                : Icons.bar_chart,
            label: l10n.navInsights,
          ),
          AdaptiveNavigationDestination(
            icon: isIOS26
                ? 'gearshape'
                : isIOS
                ? CupertinoIcons.settings
                : Icons.settings_outlined,
            selectedIcon: isIOS26
                ? 'gearshape.fill'
                : isIOS
                ? CupertinoIcons.settings_solid
                : Icons.settings,
            label: l10n.navSettings,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _tabs),
    );
  }
}
