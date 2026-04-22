import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
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
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Text(
                    l10n.wakeupTitle,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: Column(
                    children: [
                      // Image area (mock gradient)
                      Container(
                        height: 260.h,
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
                              top: 14.h,
                              left: 14.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(140),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  missionLabel,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4A3000),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Image.asset(
                                'assets/icon.png',
                                width: 120.w,
                                height: 120.h,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Info bar
                      Container(
                        color: c.card,
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.w, vertical: 14.h),
                        child: Row(
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.h,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.orange.withAlpha(25),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.asset(
                                  'assets/icon.png',
                                  width: 28.w,
                                  height: 28.h,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        color: c.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Padding(
                                      padding: EdgeInsets.only(top: 6.h),
                                      child: Text(
                                        isPM ? 'pm' : 'am',
                                        style: TextStyle(
                                          fontSize: 14.sp,
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
                                    fontSize: 14.sp,
                                    color: c.textSecondary,
                                  ),
                                ),
                                Text(
                                  '#$wakeupNumber',
                                  style: TextStyle(
                                    fontSize: 13.sp,
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
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              child: ElevatedButton(
                onPressed: withHaptic(() => Navigator.pop(context)),
                child: Text(l10n.wakeupStartMyDay),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
