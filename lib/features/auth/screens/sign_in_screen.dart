import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../onboarding/widgets/sign_in_step.dart';

/// Standalone sign-in screen reachable from the welcome page.
/// Accepts new account creation; AuthWrapper routes the user to onboarding
/// (no Firestore flag yet) or the main app (existing onboarded account).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.of(context).pop()),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SignInStep(
                title: 'Welcome back',
                subtitle: 'Sign in to restore your plan.',
                onSkip: () => Navigator.of(context).pop(),
                onSignInComplete: () => Navigator.of(context).pop(),
                showSkip: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
