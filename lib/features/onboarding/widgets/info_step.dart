import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class InfoStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? bodyText;
  // Image (icon / emoji / illustration) shown above the title.
  final Widget? imagePlaceholder;
  // Chart / graph shown below the title, so the title introduces it.
  final Widget? chartPlaceholder;
  // Optional small footnote citations rendered at the bottom of the step.
  final String? references;

  const InfoStep({
    super.key,
    required this.title,
    this.subtitle,
    this.bodyText,
    this.imagePlaceholder,
    this.chartPlaceholder,
    this.references,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cross = CrossAxisAlignment.center;
    final textAlign = TextAlign.center;

    // Always scrollable: the content block is centred while it fits the
    // viewport (min-height = available height) and scrolls instead of
    // overflowing once image + title + chart + body + references get too tall.
    // No IntrinsicHeight, so LayoutBuilder-based charts (EnergyChart,
    // TimelineComparison) passed in as placeholders keep working.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              // spaceBetween centres the content block (top/bottom anchors are
              // equal-sized) while keeping the references pinned toward the
              // bottom; gaps collapse to zero once the content overflows.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: cross,
              children: [
                SizedBox(height: 24.h),
                // Visual + text kept as one tight block (image, title,
                // subtitle, chart, body) so the spacing stays consistent
                // whatever elements are present.
                Column(
                  crossAxisAlignment: cross,
                  children: [
              if (imagePlaceholder != null) ...[
                imagePlaceholder!,
                SizedBox(height: 18.h),
              ],
              Text(
                title,
                textAlign: textAlign,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 8.h),
                Text(
                  subtitle!,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ],
              if (chartPlaceholder != null) ...[
                SizedBox(height: 18.h),
                chartPlaceholder!,
              ],
              if (bodyText != null) ...[
                SizedBox(height: 24.h),
                Text(
                  bodyText!,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: c.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
                ),
                // Scientific citations, boxed and badged to read as a research
                // source, de-emphasized toward the bottom. When absent, a
                // balancing spacer keeps the content block centred.
                if (references != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: c.separator),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('🔬', style: TextStyle(fontSize: 14.sp)),
                            SizedBox(width: 6.w),
                            Text(
                              AppLocalizations.of(context)
                                  .onboardingScienceSays,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          references!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: c.textSecondary.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(height: 24.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
