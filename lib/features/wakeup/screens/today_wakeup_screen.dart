import 'package:flutter/material.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/wakeup_session.dart';

class TodayWakeupScreen extends StatelessWidget {
  final WakeupSession session;
  final int wakeupNumber;

  const TodayWakeupScreen({
    super.key,
    required this.session,
    required this.wakeupNumber,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final ts = session.timestamp;
    final h = ts.hour > 12 ? ts.hour - 12 : (ts.hour == 0 ? 12 : ts.hour);
    final isPM = ts.hour >= 12;
    final timeStr = '$h:${ts.minute.toString().padLeft(2, '0')}';
    final dateStr = '${localizedMonth(l10n, ts.month)} ${ts.day}';
    final missionLabel = session.missionType != null
        ? localizedMissionName(l10n, session.missionType!)
        : l10n.wakeupWakeUp;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    l10n.wakeupTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      // Image area (mock gradient)
                      Container(
                        height: 260,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFE0A3),
                              Color(0xFFB8D4E8),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(140),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  missionLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A3000),
                                  ),
                                ),
                              ),
                            ),
                            const Center(
                              child: Text('🌞', style: TextStyle(fontSize: 80)),
                            ),
                          ],
                        ),
                      ),
                      // Info bar
                      Container(
                        color: c.card,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.orange.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.wb_sunny,
                                  color: AppColors.orange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: c.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        isPM ? 'pm' : 'am',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: c.textSecondary,
                                  ),
                                ),
                                Text(
                                  '#$wakeupNumber',
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
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.wakeupStartMyDay),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
