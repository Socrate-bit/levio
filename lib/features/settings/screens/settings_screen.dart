import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/cubit/alarm_cubit.dart';
import '../../alarms/services/alarm_channel.dart';
import '../cubit/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _notifications = true;

  Future<void> _printAllAlarms(BuildContext context) async {
    final flutterAlarms = context.read<AlarmCubit>().state.alarms;
    final nativeAlarms = await AlarmChannel.getAlarms();
    final nativeIds = nativeAlarms.map((a) => a['id'] as String).toSet();

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[Admin] Native AlarmKit alarms (${nativeAlarms.length}):');
    for (final native in nativeAlarms) {
      final id = native['id'] as String;
      debugPrint('  • $id');
      debugPrint('      state          : ${native['state']}');
      debugPrint('      title          : ${native['title'] ?? '-'}');
      debugPrint('      sfSymbol       : ${native['sfSymbol'] ?? '-'}');
      debugPrint('      secondaryLabel : ${native['secondaryLabel'] ?? '-'}');
      debugPrint('      isOneShot      : ${native['isOneShot']}');
      if (native['timestampMs'] != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch((native['timestampMs'] as double).toInt());
        debugPrint('      scheduledAt    : $dt');
      }
      if (native['weekdayMask'] != null) {
        debugPrint('      weekdayMask    : ${native['weekdayMask']}  hour=${native['hour']}  minute=${native['minute']}');
      }

      // Cross-reference with Flutter state
      final match = flutterAlarms.where((a) => a.id == id).firstOrNull;
      if (match != null) {
        debugPrint('      [Flutter] name       : ${match.name.isEmpty ? "(no name)" : match.name}');
        debugPrint('      [Flutter] enabled    : ${match.isEnabled}');
        debugPrint('      [Flutter] missions   : ${match.missions.map((m) => m.type.name).toList()}');
        debugPrint('      [Flutter] sound      : ${match.soundId}');
        debugPrint('      [Flutter] repeatDays : ${match.repeatDays}');
      } else {
        debugPrint('      [Flutter] ⚠ not found in Flutter state');
      }
    }

    final orphans = flutterAlarms.where((a) => !nativeIds.contains(a.id));
    if (orphans.isNotEmpty) {
      debugPrint('[Admin] Flutter-only (not in AlarmKit):');
      for (final a in orphans) {
        debugPrint('  • ${a.id}  name=${a.name}  enabled=${a.isEnabled}');
      }
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<void> _printSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList()..sort();
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[Admin] SharedPreferences (${keys.length} keys):');
    for (final key in keys) {
      final value = prefs.get(key);
      debugPrint('  $key = $value  (${value.runtimeType})');
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  Future<void> _deleteAllAlarms(BuildContext context) async {
    final cubit = context.read<AlarmCubit>();
    final ids = await AlarmChannel.getAlarmIds();
    debugPrint('[Admin] Deleting ${ids.length} alarms…');
    for (final id in ids) {
      await cubit.removeAlarm(id);
      debugPrint('[Admin] Deleted $id');
    }
    debugPrint('[Admin] All alarms deleted.');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              // Profile card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🌟', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anonymous User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signed in anonymously',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'App'),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) => _SettingsCard(children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const _Divider(),
                  _ToggleRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    value: themeMode == ThemeMode.dark,
                    onChanged: (_) =>
                        context.read<ThemeCubit>().toggle(),
                  ),
                  const _Divider(),
                  _LinkRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Default Sound',
                    value: 'Default',
                    onTap: () {},
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'About'),
              _SettingsCard(children: [
                _LinkRow(
                  icon: Icons.star_outline,
                  label: 'Rate Levio',
                  onTap: () {},
                ),
                const _Divider(),
                _LinkRow(
                  icon: Icons.share_outlined,
                  label: 'Share with Friends',
                  onTap: () {},
                ),
                const _Divider(),
                _LinkRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
                const _Divider(),
                _LinkRow(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 16),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                _SectionTitle(title: 'Admin (debug only)'),
                _SettingsCard(children: [
                  _ActionRow(
                    icon: Icons.bug_report_outlined,
                    label: 'Print All Alarms',
                    color: AppColors.orange,
                    onTap: () => _printAllAlarms(context),
                  ),
                  const _Divider(),
                  _ActionRow(
                    icon: Icons.storage_outlined,
                    label: 'Print SharedPreferences',
                    color: AppColors.orange,
                    onTap: _printSharedPrefs,
                  ),
                  const _Divider(),
                  _ActionRow(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Delete All Alarms',
                    color: Colors.red,
                    onTap: () => _deleteAllAlarms(context),
                  ),
                ]),
                const SizedBox(height: 16),
              ],
              Center(
                child: Text(
                  'Levio v0.1.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Switch(
            value: value,
            activeThumbColor: AppColors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value!,
                  style: TextStyle(
                    fontSize: 15,
                    color: c.textSecondary,
                  ),
                ),
              ),
            Icon(Icons.chevron_right, size: 18, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Divider(height: 1, color: c.separator),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
