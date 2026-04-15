import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../missions/models/mission.dart';

/// Interstitial screen shown before each mission in a multi-mission sequence.
class MissionStartScreen extends StatelessWidget {
  final int currentIndex;
  final int totalMissions;
  final MissionType missionType;
  final VoidCallback onStart;

  const MissionStartScreen({
    super.key,
    required this.currentIndex,
    required this.totalMissions,
    required this.missionType,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final info = missionInfoFor(missionType);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Text('\u{1f31e}', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            const Text(
              'Time to Wake Up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mission ${currentIndex + 1}/$totalMissions: ${info.name}',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Mission',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalMissions, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == currentIndex
                        ? Colors.white
                        : Colors.white.withAlpha(60),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
