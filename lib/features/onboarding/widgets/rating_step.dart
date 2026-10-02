import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class RatingStep extends StatelessWidget {
  const RatingStep({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          // Stars placeholder
          Container(
            height: 60.h,
            alignment: Alignment.center,
            child: Text('⭐⭐⭐⭐⭐',
                style: TextStyle(fontSize: 28.sp)),
          ),
          Text(
            l10n.onboardingRatingTitle,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.onboardingRatingSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 24.h),
          _TestimonialCard(
            name: l10n.onboardingRatingMarc,
            review: l10n.onboardingRatingMarcReview,
            avatar: 'assets/onboarding/profil_comments/man1.jpg',
            colors: c,
          ),
          SizedBox(height: 12.h),
          _TestimonialCard(
            name: l10n.onboardingRatingSophie,
            review: l10n.onboardingRatingSophieReview,
            avatar: 'assets/onboarding/profil_comments/woman1.jpg',
            colors: c,
          ),
          SizedBox(height: 12.h),
          _TestimonialCard(
            name: l10n.onboardingRatingAlex,
            review: l10n.onboardingRatingAlexReview,
            avatar: 'assets/onboarding/profil_comments/woman2.jpg',
            colors: c,
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String review;
  final String avatar;
  final AppColors colors;

  const _TestimonialCard({
    required this.name,
    required this.review,
    required this.avatar,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: colors.separator,
                backgroundImage: AssetImage(avatar),
              ),
              SizedBox(width: 10.w),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (_) => Icon(Icons.star,
                      color: const Color(0xFFFFB800), size: 16.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            review,
            style: TextStyle(
              fontSize: 14.sp,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
