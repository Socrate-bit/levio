import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_theme.dart';
import '../../onboarding/cubit/onboarding_cubit.dart';
import '../../onboarding/widgets/welcome_step.dart';
import 'sign_in_screen.dart';

/// Default screen shown when no user is authenticated.
/// Build Plan flips OnboardingCubit.isInProgress so AuthWrapper swaps to
/// OnboardingScreen; Sign In opens the standalone sign-in modal.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: WelcomeStep(
        onBuildPlan: () => context.read<OnboardingCubit>().startOnboarding(),
        onSignIn: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SignInScreen())),
      ),
    );
  }
}
