import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_glass_bar/liquid_glass_bar.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';
import 'package:levio/features/alarms/cubit/alarm_cubit.dart';
import 'package:levio/features/alarms/screens/alarm_form_screen.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

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

  void _openAlarmForm(BuildContext context) {
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

  static const _tabs = [HomeScreen(), InsightsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LiquidGlassBar(
                currentIndex: _index,
                onTap: withHapticValue((int i) => setState(() => _index = i))!,
                style: LiquidGlassBarStyle(
                  activeColor: AppColors.orange,
                  inactiveColor: c.textSecondary,
                  borderRadius: 28,
                  height: 52,
                  iconSize: 24,
                  selectedIconScale: 1.15,
                  animationDuration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.fromLTRB(20, 12, 4, 0),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                  borderColor: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xE6FFFFFF),
                  borderWidth: isDark ? 0.1 : 1.0,
                  indicatorBorderColor: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0x99FFFFFF),
                  indicatorBorderWidth: 1.5,
                  liquidGlassSettings: LiquidGlassSettings(
                    blur: 10.0,
                    thickness: 20,
                    glassColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                items: [
                  LiquidGlassBarItem(
                    iconData: Icons.home_rounded,
                    label: l10n.navHome,
                  ),
                  LiquidGlassBarItem(
                    iconData: Icons.bar_chart_rounded,
                    label: l10n.navInsights,
                  ),
                  LiquidGlassBarItem(
                    iconData: Icons.settings_rounded,
                    label: l10n.navSettings,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, left: 6),
              child: _AddAlarmCircleButton(

                onTap: () => _openAlarmForm(context),
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
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.orange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x40895EFF),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 44),
      ),
    );
  }
}
