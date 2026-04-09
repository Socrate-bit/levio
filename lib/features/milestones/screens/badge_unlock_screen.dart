import 'package:flutter/material.dart';

import '../../../shared/widgets/hexagon_badge.dart';
import '../models/badge_model.dart';

class BadgeUnlockScreen extends StatelessWidget {
  final BadgeModel badge;

  const BadgeUnlockScreen({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final dateStr = badge.earnedDate != null
        ? _formatDate(badge.earnedDate!)
        : 'Today';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Warm gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF8F0), Color(0xFFFFF0DC)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF3D2B1F)),
                    ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glow effect
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.orange.withAlpha(60),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: LargeHexagonBadge(
                            label:
                                badge.requiredDays?.toString() ?? '★',
                            color: const Color(0xFFE05C1A),
                            size: 130,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'BADGE UNLOCKED',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Color(0xFFE05C1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        badge.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D1B00),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        'Unlocked $dateStr',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B6E50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.quote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF8B6E50),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}
