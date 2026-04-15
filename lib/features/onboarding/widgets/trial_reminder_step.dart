import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class TrialReminderStep extends StatelessWidget {
  final VoidCallback onContinue;

  const TrialReminderStep({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            "We'll send you\na reminder before\nyour free trial ends",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          // Bell with notification badge
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 80,
                    color: c.textSecondary,
                  ),
                ),
                Positioned(
                  top: -4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          // No Payment Due Now
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, size: 20, color: AppColors.orange),
              const SizedBox(width: 6),
              Text(
                'No Payment Due Now',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Continue for free button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Continue For Free',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.card,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Just \$29.99 per year (\$2.50/mo)',
            style: TextStyle(fontSize: 14, color: c.textSecondary),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
