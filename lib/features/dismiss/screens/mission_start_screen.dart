import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/models/mission.dart';
import '../widgets/levio_brand_header.dart';

/// Interstitial screen shown before each mission in a multi-mission sequence.
class MissionStartScreen extends StatelessWidget {
  final int currentIndex;
  final int totalMissions;
  final MissionType missionType;
  final VoidCallback onStart;
  // Sleep (bedtime) alarm vs wake-up — drives the greeting wording.
  final bool isSleep;
  // Current streak shown as encouragement; hidden when 0 or not yet loaded.
  final int currentStreak;

  const MissionStartScreen({
    super.key,
    required this.currentIndex,
    required this.totalMissions,
    required this.missionType,
    required this.onStart,
    this.isSleep = false,
    this.currentStreak = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
    
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            const LevioBrandHeader(),
            const Spacer(),
            Image.asset('assets/icon.png', width: 130.w, height: 130.h),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                isSleep
                    ? l10n.dismissMissionTimeToWindDown
                    : l10n.dismissMissionTimeToWakeUp,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(

                  color: c.textPrimary,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.dismissMissionLabel(currentIndex + 1, totalMissions, localizedMissionName(l10n, missionType)),
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 16.sp,
              ),
            ),
            if (currentStreak > 0) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  l10n.dismissMissionStreak(currentStreak),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ElevatedButton(
                onPressed: withHaptic(onStart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.background,
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.dismissStartMission,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalMissions, (i) {
                return Container(
                  width: 8.w,
                  height: 8.h,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == currentIndex
                        ? c.textPrimary
                        : c.textSecondary.withAlpha(80),
                  ),
                );
              }),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
