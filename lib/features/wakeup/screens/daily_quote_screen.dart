import 'dart:math';

import 'package:flutter/material.dart';

const dailyQuotes = [
  ('In the middle of every difficulty lies opportunity.', 'Albert Einstein'),
  ('The secret of getting ahead is getting started.', 'Mark Twain'),
  (
    'It does not matter how slowly you go as long as you do not stop.',
    'Confucius'
  ),
  ('Success is not final, failure is not fatal.', 'Winston Churchill'),
  (
    'Believe you can and you\'re halfway there.',
    'Theodore Roosevelt'
  ),
  (
    'The only way to do great work is to love what you do.',
    'Steve Jobs'
  ),
  ('Wake up with determination, go to bed with satisfaction.', 'Unknown'),
  (
    'Every morning we are born again. What we do today matters most.',
    'Buddha'
  ),
];

class DailyQuoteScreen extends StatelessWidget {
  const DailyQuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
