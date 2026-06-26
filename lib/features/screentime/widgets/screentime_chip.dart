import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../cubit/screentime_cubit.dart';
import '../cubit/screentime_state.dart';
import '../screens/screentime_detail_screen.dart';

/// Home top-bar chip mirroring the streak chip. The icon reflects whether
/// screen-time blocking is currently active; tapping opens the detail screen.
class ScreenTimeChip extends StatelessWidget {
  const ScreenTimeChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BlocBuilder<ScreenTimeCubit, ScreenTimeState>(
      buildWhen: (p, n) => p.isActiveNow != n.isActiveNow,
      builder: (context, state) {
        final active = state.isActiveNow;
        return GestureDetector(
          onTap: withHaptic(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ScreenTimeCubit>(),
                  child: const ScreenTimeDetailScreen(),
                ),
              ),
            );
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8),
              ],
            ),
            child: Icon(
              active ? Icons.shield : Icons.shield_outlined,
              size: 20.sp,
              color: active ? AppColors.orange : c.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
