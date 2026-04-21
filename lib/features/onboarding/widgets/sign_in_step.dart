import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../auth/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class SignInStep extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback? onSignInComplete;
  final bool showSkip;
  final String title;
  final String subtitle;

  const SignInStep({
    super.key,
    required this.onSkip,
    this.onSignInComplete,
    this.showSkip = true,
    this.title = 'Create your account',
    this.subtitle = 'Save your progress and sync your plan.',
  });

  @override
  State<SignInStep> createState() => _SignInStepState();
}

class _SignInStepState extends State<SignInStep> {
  bool _loading = false;

  void _showAuthSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) (widget.onSignInComplete ?? widget.onSkip)();
    } catch (e) {
      debugPrint('[SignInStep] Google sign-in failed: $e');
      if (mounted) {
        _showAuthSnackBar(AppLocalizations.of(context).onboardingGoogleFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithApple();
      if (mounted) (widget.onSignInComplete ?? widget.onSkip)();
    } catch (e) {
      debugPrint('[SignInStep] Apple sign-in failed: $e');
      if (mounted) {
        _showAuthSnackBar(AppLocalizations.of(context).onboardingAppleFailed);
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const SizedBox(height: 32),
          // Sign in with Apple
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : withHaptic(_handleAppleSignIn),
              icon: Icon(Icons.apple, size: 24, color: c.card),
              label: Text(
                l10n.onboardingSignInApple,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.card,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Continue with Google
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _loading ? null : withHaptic(_handleGoogleSignIn),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.separator, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                l10n.onboardingSignInGoogle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
                  fontSize: 16,
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
