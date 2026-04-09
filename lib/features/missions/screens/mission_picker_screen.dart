import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/mission.dart';

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
                    MissionCategory.all => '⚡',
                    MissionCategory.trending => '🔥',
                    MissionCategory.hunts => '🔍',
                    MissionCategory.physical => '💪',
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
                          color: selected ? c.textPrimary : c.card,
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

  void _showPreview(BuildContext context, MissionInfo info) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: info.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, color: info.iconColor, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              info.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close modal
                Navigator.pop(context, info.type); // select mission
              },
              child: const Text('Choose This Mission'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => Navigator.pop(context, info.type),
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
            const Spacer(),
            if (info.type == MissionType.random)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00B5D8), width: 1),
                ),
                child: const Text(
                  '0 in pool',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00B5D8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showPreview(context, info),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w500,
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
