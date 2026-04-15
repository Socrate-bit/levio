import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/mission.dart';

/// Full-screen picker for selecting which missions to include in the random pool.
class RandomPoolPickerScreen extends StatefulWidget {
  final List<MissionType>? preselected;

  const RandomPoolPickerScreen({super.key, this.preselected});

  @override
  State<RandomPoolPickerScreen> createState() =>
      _RandomPoolPickerScreenState();
}

class _RandomPoolPickerScreenState extends State<RandomPoolPickerScreen> {
  late Set<MissionType> _selected;

  /// All selectable mission types (excludes none and random).
  static final _available = allMissions
      .where((m) => m.type != MissionType.random)
      .toList();

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected?.toSet() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                      child: Icon(Icons.close, size: 18, color: c.textPrimary),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Random Pool',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select missions to include in random rotation',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),

            // Count + select/deselect
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_selected.length} selected',
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selected.length < _available.length) {
                          _selected =
                              _available.map((m) => m.type).toSet();
                        } else {
                          _selected.clear();
                        }
                      });
                    },
                    child: Text(
                      _selected.length < _available.length
                          ? 'Select All'
                          : 'Deselect All',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: _available.length,
                itemBuilder: (_, i) {
                  final info = _available[i];
                  final selected = _selected.contains(info.type);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(info.type);
                        } else {
                          _selected.add(info.type);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.card
                            : c.card.withAlpha(80),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.green
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            info.icon,
                            color: selected
                                ? info.iconColor
                                : c.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            info.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? c.textPrimary
                                  : c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, _selected.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.background,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
