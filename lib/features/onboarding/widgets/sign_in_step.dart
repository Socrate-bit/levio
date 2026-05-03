import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../auth/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import 'email_password_modal.dart';

class SignInStep extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback? onSignInComplete;
  final bool showSkip;
  final bool blockNewAccounts;
  final String title;
  final String subtitle;

  const SignInStep({
    super.key,
    required this.onSkip,
    this.onSignInComplete,
    this.showSkip = true,
    this.blockNewAccounts = false,
    this.title = 'Create your account',
    this.subtitle = 'Save your progress and sync your plan.',
  });

  @override
  State<SignInStep> createState() => _SignInStepState();
}

class _SignInStepState extends State<SignInStep> {
  bool _loading = false;

  Future<void> _showAuthDialog(String message) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.generalOk),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle(
        blockNewAccounts: widget.blockNewAccounts,
      );
      if (mounted) (widget.onSignInComplete ?? widget.onSkip)();
    } on AccountNotFoundAuthException {
      if (mounted) {
        await _showAuthDialog(
          AppLocalizations.of(context).onboardingAccountNotFound,
        );
      }
    } catch (e) {
      debugPrint('[SignInStep] Google sign-in failed: $e');
      if (mounted) {
        await _showAuthDialog(
          AppLocalizations.of(context).onboardingGoogleFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    final ok = await showEmailPasswordModal(
      context,
      allowSignUp: !widget.blockNewAccounts,
      initialSignUpMode: !widget.blockNewAccounts,
    );
    if (ok == true && mounted) {
      (widget.onSignInComplete ?? widget.onSkip)();
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithApple(
        blockNewAccounts: widget.blockNewAccounts,
      );
      if (mounted) (widget.onSignInComplete ?? widget.onSkip)();
    } on AccountNotFoundAuthException {
      if (mounted) {
        await _showAuthDialog(
          AppLocalizations.of(context).onboardingAccountNotFound,
        );
      }
    } catch (e) {
      debugPrint('[SignInStep] Apple sign-in failed: $e');
      if (mounted) {
        await _showAuthDialog(
          AppLocalizations.of(context).onboardingAppleFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.subtitle,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 32.h),
          // Sign in with Apple
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : withHaptic(_handleAppleSignIn),
              icon: Icon(Icons.apple, size: 24.sp, color: c.card),
              label: Text(
                l10n.onboardingSignInApple,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: c.card,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Continue with Google
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: OutlinedButton(
              onPressed: _loading ? null : withHaptic(_handleGoogleSignIn),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.separator, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                l10n.onboardingSignInGoogle,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _loading ? null : withHaptic(_handleEmailAuth),
            child: Text(
              l10n.onboardingSignInEmail,
              style: TextStyle(
                fontSize: 14.sp,
                color: c.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          if (_loading)
            const CircularProgressIndicator()
          else if (widget.showSkip)
            GestureDetector(
              onTap: withHaptic(() async {
                setState(() => _loading = true);
                try {
                  await AuthService.signInAnonymously();
                } catch (e) {
                  debugPrint('[SignInStep] Anonymous sign-in failed: $e');
                }
                if (mounted) {
                  setState(() => _loading = false);
                  widget.onSkip();
                }
              }),
              child: Text(
                l10n.onboardingSkipForNow,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: c.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
