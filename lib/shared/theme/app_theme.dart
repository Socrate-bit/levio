import 'package:flutter/material.dart';

class AppColors {
  // Theme-invariant accent colors (same in both themes)
  static const orange = Color(0xFFFF6B00);
  static const orangeLight = Color(0xFFFFF0E6);
  static const green = Color(0xFF34C759);

  // Instance properties (theme-sensitive)
  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color separator;
  final Color navBackground;

  const AppColors._({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.separator,
    required this.navBackground,
  });

  static const _light = AppColors._(
    background: Color(0xFFF2F2F7),
    card: Colors.white,
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF8E8E93),
    separator: Color(0xFFE5E5EA),
    navBackground: Colors.white,
  );

  static const _dark = AppColors._(
    background: Color(0xFF1C1C1E),
    card: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E8E93),
    separator: Color(0xFF38383A),
    navBackground: Color(0xFF1C1C1E),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }
}

class AppTheme {
  static ThemeData get light {
    const bg = Color(0xFFF2F2F7);
    const card = Colors.white;
    const textPrimary = Color(0xFF1C1C1E);
    const textSecondary = Color(0xFF8E8E93);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.light,
        surface: bg,
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const darkBg = Color(0xFF1C1C1E);
    const darkCard = Color(0xFF2C2C2E);
    const darkText = Color(0xFFFFFFFF);
    const darkSecondary = Color(0xFF8E8E93);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        brightness: Brightness.dark,
        surface: darkBg,
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: darkText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyMedium: TextStyle(fontSize: 15, color: darkText),
        bodySmall: TextStyle(fontSize: 13, color: darkSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkText,
          foregroundColor: darkBg,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
