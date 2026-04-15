import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_theme.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

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
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.redeemStatus != curr.redeemStatus,
      listener: (context, state) {
        if (state.redeemStatus == ReferralRedeemStatus.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Referral code applied! You are now: ${state.userType.name}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                left: 16,
                right: 16,
              ),
            ),
          );
          context.read<AuthCubit>().clearRedeemStatus();
        }
      },
      builder: (context, state) {
        final isSubmitting =
            state.redeemStatus == ReferralRedeemStatus.submitting;
        return AlertDialog(
          backgroundColor: c.card,
          title: Text('Enter Referral Code',
              style: TextStyle(color: c.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Referral Code',
                  hintStyle: TextStyle(color: c.textSecondary),
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.separator),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.separator),
                  ),
                ),
              ),
              if (state.redeemStatus == ReferralRedeemStatus.invalid) ...[
                const SizedBox(height: 8),
                Text('Invalid referral code',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
              ],
              if (state.redeemStatus == ReferralRedeemStatus.exhausted) ...[
                const SizedBox(height: 8),
                Text('This code has reached its usage limit',
                    style: TextStyle(
                        fontSize: 13, color: Colors.orange.shade700)),
              ],
              if (state.redeemStatus == ReferralRedeemStatus.error) ...[
                const SizedBox(height: 8),
                Text('Something went wrong, please try again',
                    style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      context.read<AuthCubit>().clearRedeemStatus();
                      Navigator.of(context).pop();
                    },
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => context
                      .read<AuthCubit>()
                      .redeemReferralCode(_controller.text),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
