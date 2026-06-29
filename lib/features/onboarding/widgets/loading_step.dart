import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class LoadingStep extends StatefulWidget {
  final VoidCallback onComplete;

  /// Optional override for the checklist bullets (v2 personalizes these and
  /// adds a sleep-routine line). Falls back to the default six when null.
  final List<String>? steps;

  const LoadingStep({super.key, required this.onComplete, this.steps});

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  int get _stepCount => _resolvedSteps?.length ?? 6;

  List<String>? get _resolvedSteps => widget.steps;

  List<String> _steps(AppLocalizations l10n) =>
      _resolvedSteps ??
      [
        l10n.onboardingLoadingStep1,
        l10n.onboardingLoadingStep2,
        l10n.onboardingLoadingStep3,
        l10n.onboardingLoadingStep4,
        l10n.onboardingLoadingStep5,
        l10n.onboardingLoadingStep6,
      ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _completedCount(double progress) {
    return (progress * _stepCount).floor().clamp(0, _stepCount);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, _) {
          final progress = _progressAnimation.value;
          final percent = (progress * 100).round();
          final completed = _completedCount(progress);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 64.sp,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.onboardingLoadingTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: c.separator,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.orange),
                    minHeight: 6,
                  ),
                ),
                SizedBox(height: 32.h),
                ...List.generate(_stepCount, (i) {
                  final steps = _steps(l10n);
                  final done = i < completed;
                  final active = i == completed && completed < _stepCount;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: done
                              ? Icon(Icons.check_circle,
                                  size: 22.sp, color: AppColors.orange)
                              : active
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                AppColors.orange),
                                      ),
                                    )
                                  : Icon(Icons.circle_outlined,
                                      size: 22.sp, color: c.separator),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          steps[i],
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: done || active
                                ? c.textPrimary
                                : c.textSecondary,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Spacer(flex: 3),
              ],
            ),
          );
        },
      ),
    );
  }
}
