import 'package:flutter/material.dart';

class LuxuryTheme {
  static const Color primaryGold = Color(0xFFECC56C);
  static const Color darkGold = Color(0xFFD4AF37);
  static const Color deepGold = Color(0xFFAA7C11);

  static const Color backgroundBlack = Color(0xFF0B0807);
  static const Color backgroundDarkBrown = Color(0xFF120E0D);
  static const Color surfaceBrown = Color(0xFF1C1310);
  static const Color cardBrown = Color(0xFF2B1D19);

  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSilver = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF9E9B98);

  static const Color lightBackground = Color(0xFFF8F5EE);
  static const Color lightSurface = Color(0xFFFFFDF7);
  static const Color lightCard = Color(0xFFF0EBE0);
  static const Color lightBorder = Color(0xFFE0D6C4);
  static const Color lightGold = Color(0xFFC9963C);
  static const Color lightGoldDeep = Color(0xFF9B7120);
  static const Color lightText = Color(0xFF1A1209);
  static const Color lightTextSecondary = Color(0xFF4A3F30);
  static const Color lightTextMuted = Color(0xFF8C7B65);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: backgroundBlack,
      canvasColor: backgroundDarkBrown,
      cardColor: cardBrown,
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceBrown,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: darkGold,
        surface: surfaceBrown,
        onPrimary: backgroundBlack,
        onSecondary: backgroundBlack,
        onSurface: textWhite,
        error: Color(0xFFE57373),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        foregroundColor: textWhite,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(color: textWhite, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textWhite, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textWhite, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
        titleMedium: TextStyle(color: textSilver, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textSilver, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
        labelLarge: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: backgroundBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceBrown,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: surfaceBrown, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightGold,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightSurface,
      cardColor: lightCard,
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: lightGold,
        secondary: lightGoldDeep,
        surface: lightSurface,
        onPrimary: lightSurface,
        onSecondary: lightSurface,
        onSurface: lightText,
        error: Color(0xFFB00020),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        foregroundColor: lightText,
        centerTitle: true,
        shadowColor: Color(0x18000000),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightText, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(color: lightText, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: lightText, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: lightText, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightText, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
        titleMedium: TextStyle(color: lightTextSecondary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: lightTextSecondary, fontSize: 16),
        bodyMedium: TextStyle(color: lightTextMuted, fontSize: 14),
        labelLarge: TextStyle(color: lightGold, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightGold,
          foregroundColor: lightSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightGold,
          side: const BorderSide(color: lightGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
        labelStyle: const TextStyle(color: lightTextMuted),
        hintStyle: const TextStyle(color: lightTextMuted),
      ),
      dividerColor: lightBorder,
    );
  }
}
