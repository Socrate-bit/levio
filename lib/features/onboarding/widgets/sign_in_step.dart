import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class SignInStep extends StatelessWidget {
  final VoidCallback onSkip;

  const SignInStep({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'Create your account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your progress and sync your plan.',
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const SizedBox(height: 32),
          // Sign in with Apple
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showComingSoon(context),
              icon: Icon(Icons.apple, size: 24, color: c.card),
              label: Text(
                'Sign in with Apple',
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
              onPressed: () => _showComingSoon(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.separator, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Sign in with Email
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => _showComingSoon(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.separator, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Sign in with Email',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onSkip,
            child: Text(
              'Skip for now',
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
