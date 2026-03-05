// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  static const Color primary      = Color(0xFF00897B);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark  = Color(0xFF00695C);
  static const Color accent       = Color(0xFFFFB300);

  // Semantic
  static const Color income       = Color(0xFF2E7D32);
  static const Color expense      = Color(0xFFC62828);

  // Light surfaces (for explicit use outside Theme)
  static const Color backgroundLight   = Color(0xFFF5F7FA);
  static const Color surfaceLight      = Color(0xFFFFFFFF);
  static const Color cardLight         = Color(0xFFFFFFFF);
  static const Color textPrimary       = Color(0xFF1A1F36);
  static const Color textSecondary     = Color(0xFF6B7280);
  static const Color divider           = Color(0xFFE5EAF2);

  // Dark surfaces (for explicit use outside Theme)
  static const Color backgroundDark    = Color(0xFF0F1117);
  static const Color surfaceDark       = Color(0xFF1A1D2E);
  static const Color surfaceVariantDark= Color(0xFF252840);
  static const Color cardDark          = Color(0xFF1E2235);
  static const Color textPrimaryDark   = Color(0xFFEDF0F7);
  static const Color textSecondaryDark = Color(0xFF8B93A7);
  static const Color dividerDark       = Color(0xFF2D3148);

  // Chart colors (same in both modes)
  static const List<Color> chartColors = [
    Color(0xFF00897B), Color(0xFFFFB300), Color(0xFF1E88E5),
    Color(0xFFE53935), Color(0xFF8E24AA), Color(0xFF00ACC1),
    Color(0xFFFF7043), Color(0xFF43A047),
  ];
}

class AppTheme {
  AppTheme._();

  // ── LIGHT ──────────────────────────────────────────────────────────────────

  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary:    AppColors.primary,
      onPrimary:  Colors.white,
      secondary:  AppColors.accent,
      onSecondary: Colors.white,
      error:      Color(0xFFE53935),
      onError:    Colors.white,
      surface:    AppColors.surfaceLight,
      onSurface:  AppColors.textPrimary,
      background: AppColors.backgroundLight,
      onBackground: AppColors.textPrimary,
      surfaceVariant: Color(0xFFEEF2F7),
      onSurfaceVariant: AppColors.textSecondary,
      outline:    Color(0xFFDDE3EE),
    );
    return _build(cs, statusBarDark: true);
  }

  // ── DARK ───────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary:    AppColors.primaryLight,
      onPrimary:  Colors.black,
      secondary:  AppColors.accent,
      onSecondary: Colors.black,
      error:      Color(0xFFEF5350),
      onError:    Colors.black,
      surface:    AppColors.surfaceDark,
      onSurface:  AppColors.textPrimaryDark,
      background: AppColors.backgroundDark,
      onBackground: AppColors.textPrimaryDark,
      surfaceVariant: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline:    AppColors.dividerDark,
    );
    return _build(cs, statusBarDark: false);
  }

  // ── SHARED BUILDER ─────────────────────────────────────────────────────────
  // ALL colors come from ColorScheme — never hardcoded — so dark/light switch perfectly.

  static ThemeData _build(ColorScheme cs, {required bool statusBarDark}) {
    final isDark = cs.brightness == Brightness.dark;
    final textColor = cs.onSurface;
    final subtleColor = cs.onSurfaceVariant;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final dividerColor = cs.outline;
    final bgColor = cs.background;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
      scaffoldBackgroundColor: bgColor,

      // ── AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        actionsIconTheme: IconThemeData(color: textColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarDark ? Brightness.dark : Brightness.light,
          statusBarBrightness: statusBarDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: textColor, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
      ),

      // ── Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dividerColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      cardColor: cardColor,

      // ── Divider
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1, space: 1),

      // ── Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: subtleColor.withOpacity(0.6), fontSize: 14),
        labelStyle: TextStyle(color: subtleColor, fontSize: 14),
        prefixIconColor: subtleColor,
      ),

      // ── Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        selectedItemColor: cs.primary,
        unselectedItemColor: subtleColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // ── Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: subtleColor,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: dividerColor,
      ),

      // ── Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        contentTextStyle: TextStyle(fontSize: 14, color: subtleColor),
      ),

      // ── Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── ListTile
      listTileTheme: ListTileThemeData(
        iconColor: subtleColor,
        textColor: textColor,
        titleTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
        subtitleTextStyle: TextStyle(fontSize: 12, color: subtleColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Switch
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? cs.primary : subtleColor),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? cs.primary.withOpacity(0.3) : dividerColor),
      ),

      // ── Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: cs.primary,
        thumbColor: cs.primary,
        overlayColor: cs.primary.withOpacity(0.1),
        inactiveTrackColor: dividerColor,
      ),

      // ── Text Theme — NO hardcoded colors; uses colorScheme via apply()
      textTheme: TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -1.0),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.3),
        headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
        titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
        bodyLarge:     TextStyle(fontSize: 15, color: textColor),
        bodyMedium:    TextStyle(fontSize: 14, color: subtleColor),
        bodySmall:     TextStyle(fontSize: 12, color: subtleColor),
        labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subtleColor),
        labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: subtleColor, letterSpacing: 0.5),
      ),
    );
  }
}