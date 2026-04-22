import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../cubit/onboarding_state.dart';

class ReferralStep extends StatelessWidget {
  final String code;
  final ReferralStatus status;
  final ValueChanged<String> onCodeChanged;

  const ReferralStep({
    super.key,
    required this.code,
    required this.status,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            l10n.onboardingReferralTitle,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.onboardingReferralSubtitle,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          const Spacer(),
          TextField(
            onChanged: onCodeChanged,
            decoration: InputDecoration(
              hintText: l10n.onboardingReferralLabel,
              hintStyle: TextStyle(color: c.textSecondary),
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: c.separator),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: c.separator),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
          if (status == ReferralStatus.valid) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  l10n.onboardingReferralApplied,
                  style:
                      TextStyle(fontSize: 14.sp, color: Colors.green.shade700),
                ),
              ],
            ),
          ],
          if (status == ReferralStatus.invalid) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  l10n.onboardingReferralInvalid,
                  style: TextStyle(fontSize: 14.sp, color: Colors.red.shade700),
                ),
              ],
            ),
          ],
          if (status == ReferralStatus.exhausted) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.block, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  l10n.onboardingReferralLimit,
                  style:
                      TextStyle(fontSize: 14.sp, color: Colors.orange.shade700),
                ),
              ],
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
