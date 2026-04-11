import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class InfoStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? bodyText;
  final Widget? imagePlaceholder;
  final bool centerTitle;

  const InfoStep({
    super.key,
    required this.title,
    this.subtitle,
    this.bodyText,
    this.imagePlaceholder,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (!centerTitle)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 16, color: c.textSecondary),
              ),
            ),
          ],
          if (imagePlaceholder != null) ...[
            const Spacer(),
            imagePlaceholder!,
          ] else
            const Spacer(),
          if (centerTitle)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
                height: 1.2,
              ),
            ),
          if (bodyText != null) ...[
            const SizedBox(height: 16),
            Text(
              bodyText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
