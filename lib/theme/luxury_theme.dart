import 'package:flutter/material.dart';
import 'app_theme.dart';

export 'app_theme.dart';

/// Compatibility & convenience wrapper for the iHome design system.
/// Keeps legacy static references functional while bridging directly to [AppColors] and [AppTheme].
class LuxuryTheme {
  // Brand color mappings
  static const Color primaryGold = AppColors.primary;
  static const Color darkGold = AppColors.accent;
  static const Color deepGold = AppColors.primary;
  static const Color textGold = AppColors.accent;
  static const Color emeraldAccent = AppColors.success;

  // Dark surfaces
  static const Color backgroundBlack = AppColors.darkBackground;
  static const Color backgroundDarkBrown = AppColors.darkBackground;
  static const Color surfaceBrown = AppColors.darkSurface;
  static const Color cardBrown = AppColors.darkCard;

  // Dark texts
  static const Color textWhite = AppColors.textLight;
  static const Color textSilver = AppColors.textLightSecondary;
  static const Color textMuted = AppColors.textLightMuted;

  // Light surfaces
  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightCard = AppColors.lightCard;
  static const Color lightBorder = AppColors.lightBorder;
  static const Color lightGold = AppColors.accent;
  static const Color lightGoldDeep = AppColors.primary;
  static const Color lightText = AppColors.textDark;
  static const Color lightTextSecondary = AppColors.textDarkSecondary;
  static const Color lightTextMuted = AppColors.textDarkMuted;

  // Context-aware dynamic helpers
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkSurface
          : AppColors.lightSurface;

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.lightCard;

  static Color cardAlt(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCardAlt
          : AppColors.lightCardAlt;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textLight
          : AppColors.textDark;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textLightSecondary
          : AppColors.textDarkSecondary;

  static Color textMutedColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textLightMuted
          : AppColors.textDarkMuted;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBorder
          : AppColors.lightBorder;

  static ThemeData get darkTheme => AppTheme.darkTheme;
  static ThemeData get lightTheme => AppTheme.lightTheme;
}
