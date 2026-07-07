import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

/// True when [value] looks like a usable phone number: 7–15 digits, with an
/// optional leading `+`. Deliberately lightweight — no phone-parsing dependency.
bool isValidPhone(String value) {
  final trimmed = value.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 7 && digits.length <= 15;
}

/// Beta step: collects the user's phone number just before the paywall. Shown
/// only when the `beta_phone` remote flag is on; a valid number is required to
/// continue (enforced by the funnel's `_canContinue`).
class PhoneNumberStep extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool showInvalid;

  const PhoneNumberStep({
    super.key,
    required this.onChanged,
    this.showInvalid = false,
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
            l10n.onboardingPhoneTitle,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.onboardingPhoneSubtitle,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          const Spacer(),
          TextField(
            keyboardType: TextInputType.phone,
            autofocus: true,
            inputFormatters: [
              // Digits plus the symbols people use to write phone numbers.
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
            ],
            onChanged: onChanged,
            style: TextStyle(fontSize: 16.sp, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.onboardingPhoneHint,
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
          if (showInvalid) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  l10n.onboardingPhoneInvalid,
                  style: TextStyle(fontSize: 14.sp, color: Colors.red.shade700),
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
