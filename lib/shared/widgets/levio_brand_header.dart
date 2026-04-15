import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centered Levio logo + brand name header for screen tops.
class LevioBrandHeader extends StatelessWidget {
  final bool showBrand;
  final Color? textColor;

  const LevioBrandHeader({super.key, this.showBrand = true, this.textColor});

  @override
  Widget build(BuildContext context) {
    if (!showBrand) return const SizedBox.shrink();

    final color = textColor ?? AppColors.of(context).textPrimary;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/icon.png', width: 38, height: 38),
          const SizedBox(width: 6),
          Text(
            'Levio',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
