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
                              // Day streak / Best streak
                              Row(
                                children: [
                                  Expanded(
                                    child: _StreakStatCard(
                                      icon: Image.asset('assets/streaks.png',
                                          width: 56.w, height: 56.h),
                                      value: '${state.currentStreak}',
                                      label: l10n.milestonesDayStreak,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _StreakStatCard(
                                      icon: Text('🏆',
                                          style: TextStyle(fontSize: 44.sp)),
                                      value: '${state.longestStreak}',
                                      label: l10n.milestonesLongestStreakLabel,
                                    ),
                                  ),
                                ],
                              ),
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

class _StreakStatCard extends StatelessWidget {
  final Widget icon;
  final String value;
  final String label;

  const _StreakStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          SizedBox(height: 56.h, child: Center(child: icon)),
          SizedBox(height: 8.h),
          Text(
            value,
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
            label,
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
