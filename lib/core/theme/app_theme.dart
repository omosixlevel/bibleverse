import 'package:flutter/material.dart';

/// Bibleverse App Theme - Delightful Green & White
class AppTheme {
  // Brand Colors - Sacred but Modern
  static const Color primaryColor = Color(0xFF1A237E); // Midnight Indigo
  static const Color secondaryColor = Color(0xFF3F51B5); // Indigo
  static const Color tertiaryColor = Color(0xFF9FA8DA); // Soft Indigo
  static const Color accentColor = Color(0xFFFFC107); // Warm Gold

  // Backgrounds
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundParchment = Color(0xFFFFFAF0); // Light Parchment
  static const Color backgroundWhite = Color(0xFFF5F5F5);

  // Semantic Colors
  static const Color successColor = Color(0xFF2E7D32); // Emerald Green
  static const Color warningColor = Color(0xFFFB8C00); // Soft Orange
  static const Color errorColor = Color(0xFFD32F2F);

  // Task Type Colors
  static const Color prayerColor = Color(0xFF3949AB); // Indigo Blue
  static const Color bibleStudyColor = Color(0xFF7B1FA2); // Purple
  static const Color retreatColor = Color(0xFF1B5E20); // Deep Green
  static const Color actionColor = Color(0xFFE65100); // Deep Orange
  static const Color silenceColor = Color(0xFF455A64); // Blue Grey
  static const Color worshipColor = Color(0xFFC2185B); // Pink
  static const Color tellMeColor = Color(0xFF0097A7); // Cyan

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundParchment,

      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceWhite,
        background: backgroundParchment,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),

      // AppBar Theme - Green with White text
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      // Card Theme - White with soft shadow
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Input Decoration - Light Green background tint
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F8E9), // Green 50
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: primaryColor),

      // Divider
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),

      // Typography
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
          color: primaryColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
      ),
    );
  }

  // Specialized TextStyles
  static TextStyle get verseStyle => const TextStyle(
    fontStyle: FontStyle.italic,
    fontFamily: 'Georgia', // Serif for Scripture
    fontSize: 17,
    height: 1.6,
    color: primaryColor,
  );

  static TextStyle get parchmentStyle => const TextStyle(
    fontFamily: 'Georgia',
    color: Color(0xFF5D4037), // Balanced brown for parchment
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
