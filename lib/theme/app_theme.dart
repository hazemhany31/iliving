import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// iLiving Design Tokens — Extracted from Abu Hossain Real Estate Reference
// ─────────────────────────────────────────────────────────────────────────────
// Design philosophy: calm white-space-rich layouts, pill-shaped controls,
// ultra-soft floating shadows, single-accent-per-screen, strong image-first
// visual hierarchy, generous corner radii.
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // ── Brand / Primary ────────────────────────────────────────────────────────
  /// Charcoal-black used for primary CTAs, headings, and strong UI anchors.
  static const Color primary = Color(0xFF1A1A2E);

  /// Soft blue accent — used sparingly: one element per screen max (price tag,
  /// active filter, link).
  static const Color accent = Color(0xFF4A90D9);

  /// Coral highlight — extremely sparingly: favorite heart, urgent badge.
  static const Color highlight = Color(0xFFF4845F);

  // ── Light theme surfaces ───────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF7F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF2F2F7); // search bar fill, chip inactive bg
  static const Color lightBorder = Color(0xFFE8E8ED); // very subtle, almost invisible

  // ── Dark theme surfaces ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF101014);
  static const Color darkSurface = Color(0xFF1C1C22);
  static const Color darkCard = Color(0xFF26262E);
  static const Color darkCardAlt = Color(0xFF2E2E38);
  static const Color darkBorder = Color(0xFF38383F);

  // ── Text / ink — Light mode ────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1A2E);          // primary headings
  static const Color textDarkSecondary = Color(0xFF6B7280);  // body / descriptions
  static const Color textDarkMuted = Color(0xFF9CA3AF);      // labels, meta, timestamps

  // ── Text / ink — Dark mode ─────────────────────────────────────────────────
  static const Color textLight = Color(0xFFF9F9FB);
  static const Color textLightSecondary = Color(0xFFB0B0BA);
  static const Color textLightMuted = Color(0xFF6E6E78);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);
  static const Color info = Color(0xFF5AC8FA);

  // ── Legacy compatibility (kept for compile safety, maps to new values) ────
  static const Color primaryBlue = accent;
  static const Color primaryTeal = Color(0xFF5AC8FA);
  static const Color primaryDark = primary;
}

class AppGradients {
  /// Subtle card sheen — white to near-white, used on hero overlays.
  static const LinearGradient cardSheen = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0xCCFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Image-overlay gradient (bottom-darkening for text readability on images).
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xCC000000), Color(0x00000000)],
  );

  /// Primary button gradient — subtle charcoal depth.
  static const LinearGradient primaryButton = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark-mode card subtle gradient.
  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0xFF26262E), Color(0xFF1C1C22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy compatibility
  static const LinearGradient primary = primaryButton;
  static const LinearGradient secondary = primaryButton;
  static const LinearGradient accent = LinearGradient(
    colors: [Color(0xFF4A90D9), Color(0xFF5AC8FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const String fontFamily = 'Outfit';

  // ── Display / Hero ─────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ── Titles ─────────────────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ── Body ───────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ── Labels / Meta ──────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shadows — ultra-soft, floating, low-opacity
// ─────────────────────────────────────────────────────────────────────────────

class AppShadows {
  /// Default card shadow — barely visible, creates floating effect.
  static List<BoxShadow> get soft {
    return [
      BoxShadow(
        color: const Color(0xFF1A1A2E).withAlpha(10), // ~4% opacity
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: const Color(0xFF1A1A2E).withAlpha(5), // ~2% opacity
        blurRadius: 8,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ];
  }

  /// Elevated card shadow — for modals, floating nav, sticky bars.
  static List<BoxShadow> get elevated {
    return [
      BoxShadow(
        color: const Color(0xFF1A1A2E).withAlpha(15), // ~6% opacity
        blurRadius: 40,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: const Color(0xFF1A1A2E).withAlpha(8), // ~3% opacity
        blurRadius: 12,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ];
  }

  /// Dark-mode soft shadow.
  static List<BoxShadow> get dark {
    return [
      BoxShadow(
        color: Colors.black.withAlpha(40), // ~16% opacity
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ];
  }

  /// Dark-mode soft shadow alias
  static List<BoxShadow> get darkSoft => dark;

  /// Dark-mode elevated shadow.
  static List<BoxShadow> get darkElevated {
    return [
      BoxShadow(
        color: Colors.black.withAlpha(60), // ~24% opacity
        blurRadius: 40,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      ),
    ];
  }

  // Legacy compatibility
  static List<BoxShadow> get light => soft;
  static List<BoxShadow> get glow {
    return [
      BoxShadow(
        color: AppColors.accent.withAlpha(40),
        blurRadius: 16,
        spreadRadius: 0,
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Border Radius — generous, pill-first
// ─────────────────────────────────────────────────────────────────────────────

class AppBorderRadius {
  static final BorderRadius small = BorderRadius.circular(12);
  static final BorderRadius medium = BorderRadius.circular(16);
  static final BorderRadius large = BorderRadius.circular(20);
  static final BorderRadius round = BorderRadius.circular(28);
  static final BorderRadius pill = BorderRadius.circular(100);
}

// ─────────────────────────────────────────────────────────────────────────────
// Spacing — generous breathing room
// ─────────────────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double md = 16.0;
  static const double l = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;

  /// Standard horizontal page margin.
  static const double pageHorizontal = 20.0;

  /// Standard card internal padding.
  static const double cardPadding = 16.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorations — pre-built box decorations for consistency
// ─────────────────────────────────────────────────────────────────────────────

class AppDecorations {
  /// Standard card decoration — white bg, soft shadow, no visible border.
  static BoxDecoration card({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: AppBorderRadius.medium,
      boxShadow: isDark ? AppShadows.dark : AppShadows.soft,
    );
  }

  /// Elevated floating card (nav bar, modals, sticky bars).
  static BoxDecoration floatingCard({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: AppBorderRadius.round,
      boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
    );
  }

  /// Search bar / input field decoration — pill-shaped, subtle fill.
  static BoxDecoration searchBar({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
      borderRadius: AppBorderRadius.pill,
    );
  }

  /// Chip / filter pill — inactive state.
  static BoxDecoration chipInactive({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
      borderRadius: AppBorderRadius.pill,
    );
  }

  /// Chip / filter pill — active state.
  static BoxDecoration chipActive({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? AppColors.primary : AppColors.primary,
      borderRadius: AppBorderRadius.pill,
    );
  }

  /// Image card (property listing) — full-bleed image with rounded corners.
  static BoxDecoration imageCard() {
    return BoxDecoration(
      borderRadius: AppBorderRadius.medium,
      boxShadow: AppShadows.soft,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Data
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  // ═════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME — Primary theme, matching reference
  // ═════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightSurface,
      cardColor: AppColors.lightCard,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        tertiary: AppColors.highlight,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textDark,
        error: AppColors.error,
        outline: AppColors.lightBorder,
      ),

      // ── App Bar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),

      // ── Text Theme ───────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.textDark),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.textDark),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.textDark),
        headlineMedium: AppTextStyles.titleLarge.copyWith(color: AppColors.textDark, fontSize: 20),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.textDark),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.textDarkSecondary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDarkSecondary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDarkMuted),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.textDarkMuted),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.textDarkMuted),
      ),

      // ── Elevated Button — Pill-shaped, charcoal primary ──────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
      ),

      // ── Outlined Button — Pill-shaped, subtle border ─────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
      ),

      // ── Input Decoration — Pill-shaped, subtle fill ──────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCardAlt,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(
          color: AppColors.textDarkMuted,
          fontFamily: 'Outfit',
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textDarkMuted,
          fontFamily: 'Outfit',
          fontSize: 14,
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.large,
        ),
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),

      // ── Snack Bar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.medium,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerColor: AppColors.lightBorder,
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightCardAlt,
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.pill,
        ),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textDarkSecondary,
        size: 22,
      ),

      // ── Tab Bar ──────────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textDarkMuted,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  DARK THEME — Refined companion (not just inverted light)
  // ═════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkSurface,
      cardColor: AppColors.darkCard,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        tertiary: AppColors.highlight,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLight,
        error: AppColors.error,
        outline: AppColors.darkBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textLight,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.textLight),
        displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.textLight),
        displaySmall: AppTextStyles.displaySmall.copyWith(color: AppColors.textLight),
        headlineMedium: AppTextStyles.titleLarge.copyWith(color: AppColors.textLight, fontSize: 20),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.textLight),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.textLightSecondary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLightSecondary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLightMuted),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.accent),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.textLightMuted),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.textLightMuted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCardAlt,
        border: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.small,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(
          color: AppColors.textLightMuted,
          fontFamily: 'Outfit',
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textLightMuted,
          fontFamily: 'Outfit',
          fontSize: 14,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.large,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCard,
        contentTextStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          color: AppColors.textLight,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.medium,
        ),
      ),

      dividerColor: AppColors.darkBorder,
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCardAlt,
        selectedColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.pill,
        ),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textLightSecondary,
        size: 22,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textLightMuted,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
