// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/features/alarms/services/alarm_readiness_guard.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'theme/app_theme.dart';
import 'utils/haptic_utils.dart';
import 'package:levio/features/alarms/cubit/alarm_cubit.dart';
import 'package:levio/features/alarms/screens/alarm_form_screen.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../features/alarms/screens/alarms_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/insights/screens/insights_screen.dart';
import '../features/subscription/services/analytics_service.dart';

class BottomNavShell extends StatefulWidget {
  final int initialIndex;
  const BottomNavShell({super.key, this.initialIndex = 0});

  @override
  State<BottomNavShell> createState() => BottomNavShellState();

  static BottomNavShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<BottomNavShellState>();
}

class BottomNavShellState extends State<BottomNavShell>
    with SingleTickerProviderStateMixin {
  late int _index;

  // Drives the add-alarm button's appearance on the alarms tab.
  late final AnimationController _fabController;
  late final Animation<double> _fabSize; // width/fade (no overshoot)
  late final Animation<double> _fabScale; // pop-in scale (overshoots)

  static const _alarmsIndex = 1;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _index == _alarmsIndex ? 1.0 : 0.0,
    );
    _fabSize = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // Show the add-alarm button only on the alarms tab.
  void _syncFab() {
    if (_index == _alarmsIndex) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  static const _tabNames = ['home', 'alarms', 'insights'];

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _syncFab();
    AnalyticsService.capture(AnalyticsService.navTabSelected, {
      'tab': _tabNames[index],
      'index': index,
    });
  }

  void navigateTo(int index) => _selectTab(index);

  void _openAlarmForm(BuildContext context) async {
    if (!await AlarmReadinessGuard.check(context)) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AlarmCubit>(),
          child: const AlarmFormScreen(),
        ),
      ),
    );
  }

  static const _tabs = [
    HomeScreen(),
    AlarmsScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 16.h, left: 24.w, right: 24.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GlassBottomBar(
                selectedIndex: _index,
                onTabSelected: withHapticValue(_selectTab)!,
                // Outer Padding owns the margins; let the bar fill the slot.
                horizontalPadding: 0,
                verticalPadding: 0,
                barHeight: 80.h,
                iconSize: 35.sp,
                labelFontSize: 11.sp,
                selectedIconColor: c.textPrimary,
                unselectedIconColor: c.textSecondary,
                selectedLabelColor: c.textPrimary,
                unselectedLabelColor: c.textSecondary,
                indicatorColor: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                quality: GlassQuality.premium,
                interactionBehavior: GlassInteractionBehavior.full,
                settings: LiquidGlassSettings(
                  glassColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.85),
                  thickness: 20,
                  blur: 2,
                ),
                tabs: [
                  GlassBottomBarTab(
                    label: l10n.navHome,
                    icon: const Icon(Icons.home_rounded),
                  ),
                  GlassBottomBarTab(
                    label: l10n.navAlarms,
                    icon: const Icon(Icons.alarm_rounded),
                  ),
                  GlassBottomBarTab(
                    label: l10n.navInsights,
                    icon: const Icon(Icons.bar_chart_rounded),
                  ),
                ],
              ),
            ),
            // The button pops in place with a little rebound (no sliding),
            // while its reserved footprint collapses so the nav bar re-centers
            // when hidden. OverflowBox keeps the button full-size (pinned to the
            // right) as the surrounding slot width animates.
            AnimatedBuilder(
              animation: _fabSize,
              builder: (context, child) {
                final t = _fabSize.value.clamp(0.0, 1.0);
                return SizedBox(width: (80.w + 12.w) * t, child: child);
              },
              child: OverflowBox(
                minWidth: 80.w + 12.w,
                maxWidth: 80.w + 12.w,
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: ScaleTransition(
                    scale: _fabScale,
                    child: FadeTransition(
                      opacity: _fabSize,
                      child: _AddAlarmCircleButton(
                        onTap: () => _openAlarmForm(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAlarmCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAlarmCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: withMediumHaptic(onTap),
      child: Container(
        width: 80.w,
        height: 80.h,
        decoration: BoxDecoration(
          color: AppColors.of(context).textPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x40895EFF),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: AppColors.of(context).background,
          size: 44.sp,
        ),
      ),
    );
  }
}
