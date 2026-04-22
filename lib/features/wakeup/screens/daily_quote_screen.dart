import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/utils/haptic_utils.dart';

class DailyQuoteScreen extends StatelessWidget {
  const DailyQuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dailyQuotes = [
      (l10n.quoteEinstein, l10n.quoteEinsteinAuthor),
      (l10n.quoteTwain, l10n.quoteTwainAuthor),
      (l10n.quoteConfucius, l10n.quoteConfuciusAuthor),
      (l10n.quoteChurchill, l10n.quoteChurchillAuthor),
      (l10n.quoteRoosevelt, l10n.quoteRooseveltAuthor),
      (l10n.quoteJobs, l10n.quoteJobsAuthor),
      (l10n.quoteUnknown, l10n.quoteUnknownAuthor),
      (l10n.quoteBuddha, l10n.quoteBuddhaAuthor),
    ];
    final (quote, author) = dailyQuotes[Random().nextInt(dailyQuotes.length)];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB8D4E8),
                  Color(0xFFCCAEB8),
                  Color(0xFFE8C4A0),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(context)),
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18.sp, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\u201C',
                            style: TextStyle(
                              fontSize: 48.sp,
                              color: Colors.white54,
                              height: 0.8,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            quote,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF3D2B1F),
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 32.h),
                          Text(
                            author.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13.sp,
                              letterSpacing: 2,
                              color: const Color(0xFF6B4C3B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
