import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../alarms/services/notification_service.dart';

class NotificationStep extends StatelessWidget {
  final VoidCallback onNext;

  const NotificationStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: c.textPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications, size: 40.sp, color: c.card),
          ),
          SizedBox(height: 32.h),
          Text(
            l10n.onboardingNotificationTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.onboardingNotificationSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: withHaptic(() async {
                await NotificationService.requestPermission();
                onNext();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                l10n.onboardingNotificationEnable,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: c.card,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: withHaptic(onNext),
            child: Text(
              l10n.onboardingNotificationNotNow,
              style: TextStyle(
                fontSize: 16.sp,
                color: c.textSecondary,
              ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
