import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/mission.dart';
import '../models/mission_config.dart';
import '../widgets/mission_config_modal.dart';

class MissionPickerScreen extends StatefulWidget {
  const MissionPickerScreen({super.key});

  @override
  State<MissionPickerScreen> createState() => _MissionPickerScreenState();
}

class _MissionPickerScreenState extends State<MissionPickerScreen> {
  MissionCategory _filter = MissionCategory.all;

  List<MissionInfo> get _filtered {
    if (_filter == MissionCategory.all) return allMissions;
    return allMissions.where((m) => m.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18, color: c.textPrimary),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Choose Mission',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Filter tabs
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: MissionCategory.values.map((cat) {
                  final label = switch (cat) {
                    MissionCategory.all => 'All',
                    MissionCategory.trending => 'Trending',
                    MissionCategory.hunts => 'Hunts',
                    MissionCategory.physical => 'Physical',
                  };
                  final icon = switch (cat) {
                    MissionCategory.all => '\u26a1',
                    MissionCategory.trending => '\ud83d\udd25',
                    MissionCategory.hunts => '\ud83d\udd0d',
                    MissionCategory.physical => '\ud83d\udcaa',
                  };
                  final selected = _filter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.orange : c.card,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$icon $label',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) =>
                    _MissionCard(info: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final MissionInfo info;
  const _MissionCard({required this.info});

  Future<void> _onTap(BuildContext context) async {
    final config = await showMissionConfigModal(context, info);
    if (config != null && context.mounted) {
      Navigator.pop(context, config);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: info.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, color: info.iconColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              info.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.description,
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
