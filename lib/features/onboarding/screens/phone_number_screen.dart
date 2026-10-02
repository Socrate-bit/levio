import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../shared/widgets/loading_barrier.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/phone_number_step.dart';

/// Beta phone-number collection, shown once right after the paywall (gated by
/// the `beta_phone` flag). Mandatory: no skip and no back — it closes only
/// once a valid number has been saved.
class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  bool _saving = false;

  // Saves the number, then closes the screen; stays open with a message when
  // the save fails so the number can be retried.
  Future<void> _submit() async {
    if (_saving) return;
    final cubit = context.read<OnboardingCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final saved = await cubit.savePhoneNumber();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.onboardingNetworkError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        buildWhen: (prev, curr) => prev.phoneNumber != curr.phoneNumber,
        builder: (context, state) {
          final valid = isValidPhone(state.phoneNumber);
          return Scaffold(
            backgroundColor: c.background,
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: PhoneNumberStep(
                          onChanged: context
                              .read<OnboardingCubit>()
                              .setPhoneNumber,
                          showInvalid: state.phoneNumber.isNotEmpty && !valid,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: valid ? withHaptic(_submit) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.textPrimary,
                              foregroundColor: c.card,
                              disabledBackgroundColor: c.separator,
                              disabledForegroundColor: c.textSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28.r),
                              ),
                            ),
                            child: Text(
                              l10n.onboardingContinue,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_saving) const Positioned.fill(child: LoadingBarrier()),
              ],
            ),
          );
        },
      ),
    );
  }
}
