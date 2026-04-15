import 'dart:math';

import 'package:flutter/material.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

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
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '\u201C',
                            style: TextStyle(
                              fontSize: 48,
                              color: Colors.white54,
                              height: 0.8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            quote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF3D2B1F),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            author.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              letterSpacing: 2,
                              color: Color(0xFF6B4C3B),
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
