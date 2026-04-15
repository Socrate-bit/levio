import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_channel.dart';

class NotificationStep extends StatelessWidget {
  final VoidCallback onNext;

  const NotificationStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
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
            l10n.onboardingNotificationTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingNotificationSubtitle,
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
                l10n.onboardingNotificationEnable,
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
              l10n.onboardingNotificationNotNow,
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
