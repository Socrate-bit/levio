import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../subscription/cubit/subscription_cubit.dart';
import '../../subscription/cubit/subscription_state.dart';

/// Dialog for entering a referral code from the settings screen.
class ReferralCodeDialog extends StatefulWidget {
  const ReferralCodeDialog({super.key});

  @override
  State<ReferralCodeDialog> createState() => _ReferralCodeDialogState();
}

class _ReferralCodeDialogState extends State<ReferralCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listenWhen: (prev, curr) => prev.redeemStatus != curr.redeemStatus,
      listener: (context, state) {
        if (state.redeemStatus == ReferralRedeemStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  l10n.referralApplied(state.userType.name)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                left: 16.w,
                right: 16.w,
              ),
            ),
          );
          context.read<SubscriptionCubit>().clearRedeemStatus();
        }
      },
      builder: (context, state) {
        final isSubmitting =
            state.redeemStatus == ReferralRedeemStatus.submitting;
        return AlertDialog(
          backgroundColor: c.card,
          title: Text(l10n.referralTitle,
              style: TextStyle(color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  hintText: l10n.referralCodeLabel,
                  hintStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: c.separator),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: c.separator),
                  ),
                ),
              ),
              if (state.redeemStatus == ReferralRedeemStatus.invalid) ...[
                SizedBox(height: 8.h),
                Text(l10n.referralInvalid,
                    style: TextStyle(fontSize: 13.sp, color: Colors.red.shade700)),
              ],
              if (state.redeemStatus == ReferralRedeemStatus.exhausted) ...[
                SizedBox(height: 8.h),
                Text(l10n.referralUsageLimit,
                    style: TextStyle(
                        fontSize: 13.sp, color: Colors.orange.shade700)),
              ],
              if (state.redeemStatus == ReferralRedeemStatus.error) ...[
                SizedBox(height: 8.h),
                Text(l10n.referralError,
                    style: TextStyle(fontSize: 13.sp, color: Colors.red.shade700)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : withHaptic(() {
                      context.read<SubscriptionCubit>().clearRedeemStatus();
                      Navigator.of(context).pop();
                    }),
              child: Text(l10n.referralCancel, style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : withHaptic(() => context
                      .read<SubscriptionCubit>()
                      .redeemReferralCode(_controller.text)),
              child: isSubmitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.referralSubmit,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
