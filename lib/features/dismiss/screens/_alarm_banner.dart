import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

/// Shared alarm banner used at the top of all dismiss screens.
class AlarmBanner extends StatelessWidget {
  final String label;

  const AlarmBanner({super.key, this.label = 'Alarm #1'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.alarm, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Wayk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run,
              color: AppColors.orange,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
