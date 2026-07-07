import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';

/// Small sun/moon badge distinguishing a wake-up alarm from a sleep (bedtime)
/// alarm. Shared by the home cards and the alarm list.
class AlarmKindIcon extends StatelessWidget {
  final bool isSleep;
  final double size;
  const AlarmKindIcon({super.key, required this.isSleep, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final color = isSleep ? AppColors.of(context).purpleDeep : AppColors.orange;
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSleep ? Icons.nightlight_round : Icons.wb_sunny,
        size: (size * 0.58).sp,
        color: color,
      ),
    );
  }
}
