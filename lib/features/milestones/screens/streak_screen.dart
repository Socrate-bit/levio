import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../cubit/milestones_cubit.dart';
import '../cubit/milestones_state.dart';
import '../widgets/how_streaks_work.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MilestonesCubit()..load(),
      child: const _StreakView(),
    );
  }
}

class _StreakView extends StatelessWidget {
  const _StreakView();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<MilestonesCubit, MilestonesState>(
      builder: (ctx, state) {
        return Scaffold(
          backgroundColor: c.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: withHaptic(() => Navigator.pop(ctx)),
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color: c.card,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              size: 18.sp, color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.insightsStreakSection,
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: c.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              // Current streak
                              _CurrentStreakCard(streak: state.currentStreak),
                              SizedBox(height: 12.h),
                              // Longest streak
                              _LongestStreakBox(longest: state.longestStreak),
                              SizedBox(height: 16.h),
                              // How Streaks Work (always visible here)
                              const HowStreaksWork(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrentStreakCard extends StatelessWidget {
  final int streak;

  const _CurrentStreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Image.asset('assets/streaks.png', width: 72.w, height: 72.h),
          SizedBox(height: 8.h),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 40.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.milestonesDayStreak,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LongestStreakBox extends StatelessWidget {
  final int longest;

  const _LongestStreakBox({required this.longest});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Image.asset('assets/streaks.png', width: 20.w, height: 20.h),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.milestonesLongestStreak(longest),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              Text(
                l10n.milestonesLongestStreakLabel,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
