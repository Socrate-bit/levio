import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';

class InfoStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? bodyText;
  final Widget? imagePlaceholder;
  final bool centerTitle;

  const InfoStep({
    super.key,
    required this.title,
    this.subtitle,
    this.bodyText,
    this.imagePlaceholder,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          if (!centerTitle)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
              ),
            ),
          ],
          if (imagePlaceholder != null) ...[
            const Spacer(),
            imagePlaceholder!,
          ] else
            const Spacer(),
          if (centerTitle)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
          if (bodyText != null) ...[
            SizedBox(height: 16.h),
            Text(
              bodyText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
