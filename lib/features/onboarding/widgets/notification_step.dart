import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_channel.dart';

class NotificationStep extends StatelessWidget {
  final VoidCallback onNext;

  const NotificationStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications, size: 40, color: c.card),
          ),
          const SizedBox(height: 32),
          Text(
            'Stay on track with reminders',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We'll send a gentle nudge so you never miss your wake-up time.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await AlarmChannel.requestAuthorization();
                onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Enable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.card,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onNext,
            child: Text(
              'Not now',
              style: TextStyle(
                fontSize: 16,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
