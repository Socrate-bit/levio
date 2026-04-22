import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';

/// Centered Levio logo + brand name header for screen tops.
class LevioBrandHeader extends StatelessWidget {
  final bool showBrand;
  final Color? textColor;

  const LevioBrandHeader({super.key, this.showBrand = true, this.textColor});

  @override
  Widget build(BuildContext context) {
    if (!showBrand) return const SizedBox.shrink();

    final color = textColor ?? AppColors.of(context).textPrimary;
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon.png', width: 40.w, height: 40.h),
          SizedBox(width: 12.w),
          Text(
            'Levio',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }
}
