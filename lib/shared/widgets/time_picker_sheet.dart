import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// Shows the shared hour:minute Cupertino wheel picker in a bottom sheet and
/// resolves with the chosen [TimeOfDay], or null if dismissed.
///
/// Extracted from the alarm form so the alarm and screen-time features share a
/// single time-picker implementation.
Future<TimeOfDay?> showTimePickerSheet(
  BuildContext context, {
  required TimeOfDay initial,
  String? title,
}) {
  final c = AppColors.of(context);
  final l10n = AppLocalizations.of(context);
  var hour = initial.hour;
  var minute = initial.minute;

  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: c.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: Row(
              children: [
                Text(
                  title ?? l10n.alarmFormSetTime,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: withHaptic(
                    () => Navigator.pop(ctx, TimeOfDay(hour: hour, minute: minute)),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      l10n.alarmFormDone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200.h,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: hour),
                    itemExtent: 40.h,
                    onSelectedItemChanged: (i) => hour = i,
                    children: List.generate(
                      24,
                      (i) => Center(
                        child: Text(
                          i.toString().padLeft(2, '0'),
                          style: TextStyle(fontSize: 22.sp, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: minute),
                    itemExtent: 40.h,
                    onSelectedItemChanged: (i) => minute = i,
                    children: List.generate(
                      60,
                      (i) => Center(
                        child: Text(
                          i.toString().padLeft(2, '0'),
                          style: TextStyle(fontSize: 22.sp, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
