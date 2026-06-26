import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../cubit/screentime_cubit.dart';
import '../cubit/screentime_state.dart';

/// Non-dismissible dialog that reflects the cubit's unlock countdown. Holds no
/// timer of its own — the countdown (and its focus-loss reset) live entirely in
/// [ScreenTimeCubit], so backgrounding the app restarts the count automatically.
///
/// Auto-pops when the controls become unlocked.
class UnlockCountdownDialog extends StatelessWidget {
  const UnlockCountdownDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocListener<ScreenTimeCubit, ScreenTimeState>(
      listenWhen: (prev, curr) =>
          prev.controlsUnlocked != curr.controlsUnlocked ||
          prev.unlockInProgress != curr.unlockInProgress,
      listener: (context, state) {
        // Close when unlocked or when the countdown was cancelled externally.
        if (state.controlsUnlocked || !state.unlockInProgress) {
          Navigator.of(context).maybePop();
        }
      },
      child: PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: BlocBuilder<ScreenTimeCubit, ScreenTimeState>(
              buildWhen: (p, n) => p.unlockCountdown != n.unlockCountdown,
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.screenTimeUnlockCountdownTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: 96.w,
                      height: 96.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 96.w,
                            height: 96.w,
                            child: CircularProgressIndicator(
                              value: state.unlockCountdown /
                                  kUnlockCountdownSeconds,
                              strokeWidth: 6,
                              backgroundColor: c.separator,
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.orange,
                              ),
                            ),
                          ),
                          Text(
                            '${state.unlockCountdown}',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      l10n.screenTimeUnlockCountdownHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                    ),
                    SizedBox(height: 20.h),
                    TextButton(
                      onPressed: withHaptic(() {
                        context.read<ScreenTimeCubit>().cancelUnlock();
                        Navigator.of(context).maybePop();
                      }),
                      child: Text(
                        l10n.screenTimeUnlockConfirmCancel,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
