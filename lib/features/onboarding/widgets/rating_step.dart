import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class RatingStep extends StatelessWidget {
  const RatingStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Stars placeholder
          Container(
            height: 60,
            alignment: Alignment.center,
            child: const Text('🏅⭐⭐⭐⭐⭐🏅',
                style: TextStyle(fontSize: 28)),
          ),
          Text(
            'Give us a rating',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Levio was made for\npeople like you',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _TestimonialCard(
            name: 'Marc L.',
            review:
                "I used to set 5 alarms every morning. Now I wake up on the first one and actually feel good about it.",
            colors: c,
          ),
          const SizedBox(height: 12),
          _TestimonialCard(
            name: 'Sophie D.',
            review:
                "The mission feature is brilliant. Doing push-ups at 6am sounds crazy, but it genuinely wakes me up faster than coffee.",
            colors: c,
          ),
          const SizedBox(height: 12),
          _TestimonialCard(
            name: 'Alex T.',
            review:
                "Finally an alarm app that actually works. I've tried everything and Levio is the only one that gets me out of bed.",
            colors: c,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String review;
  final AppColors colors;

  const _TestimonialCard({
    required this.name,
    required this.review,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.separator,
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (_) => const Icon(Icons.star,
                      color: Color(0xFFFFB800), size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
