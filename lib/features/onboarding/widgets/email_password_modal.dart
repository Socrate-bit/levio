import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../auth/auth_service.dart';
import '../../subscription/services/analytics_service.dart';

/// Shows a bottom sheet for email/password sign-in. When [allowSignUp] is true
/// the sheet exposes a toggle to switch into sign-up mode. Returns true on
/// successful auth, false/null otherwise.
Future<bool?> showEmailPasswordModal(
  BuildContext context, {
  bool allowSignUp = true,
  bool initialSignUpMode = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _EmailPasswordSheet(allowSignUp: allowSignUp, initialSignUpMode: initialSignUpMode),
  );
}

class _EmailPasswordSheet extends StatefulWidget {
  final bool allowSignUp;
  final bool initialSignUpMode;
  const _EmailPasswordSheet({required this.allowSignUp, required this.initialSignUpMode});

  @override
  State<_EmailPasswordSheet> createState() => _EmailPasswordSheetState();
}

class _EmailPasswordSheetState extends State<_EmailPasswordSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUpMode = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signUpMode = widget.initialSignUpMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.onboardingEmailEmptyError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_signUpMode) {
        await AuthService.signUpWithEmail(email: email, password: password);
      } else {
        await AuthService.signInWithEmail(email: email, password: password);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on EmailAuthException catch (e, st) {
      AnalyticsService.trackError('EmailPasswordModal._submit.emailAuth', e, st);
      if (mounted) setState(() => _error = e.message);
    } catch (e, st) {
      debugPrint('[EmailPasswordModal] auth failed: $e');
      AnalyticsService.trackError('EmailPasswordModal._submit', e, st);
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).onboardingGoogleFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = _signUpMode
        ? l10n.onboardingEmailModalSignUpTitle
        : l10n.onboardingEmailModalSignInTitle;
    final actionLabel = _signUpMode
        ? l10n.onboardingEmailSignUpAction
        : l10n.onboardingEmailSignInAction;
    final togglePrompt = _signUpMode
        ? l10n.onboardingEmailHasAccount
        : l10n.onboardingEmailNoAccount;
    final toggleAction = _signUpMode
        ? l10n.onboardingEmailSignInAction
        : l10n.onboardingEmailSignUpAction;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: c.separator,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _emailController,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.onboardingEmailLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _passwordController,
                enabled: !_loading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.onboardingPasswordLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 12.h),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 13.sp, color: Colors.red),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _loading ? null : withHaptic(_submit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.textPrimary,
                    foregroundColor: c.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26.r),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(c.card),
                          ),
                        )
                      : Text(
                          actionLabel,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (widget.allowSignUp) ...[
                SizedBox(height: 12.h),
                Center(
                  child: GestureDetector(
                    onTap: _loading
                        ? null
                        : withHaptic(() => setState(() {
                              _signUpMode = !_signUpMode;
                              _error = null;
                            })),
                    child: RichText(
                      text: TextSpan(
                        style:
                            TextStyle(fontSize: 14.sp, color: c.textSecondary),
                        children: [
                          TextSpan(text: togglePrompt),
                          TextSpan(
                            text: toggleAction,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
