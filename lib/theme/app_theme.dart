import 'package:flutter/material.dart';
import 'combofox_theme.dart';

// ═══════════════════════════════════════════════════════════════
// ComboFox Arcade OS Theme — Neon retro-futuristic design system
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // Updated to match ComboFoxColors — all existing imports stay valid.
  static const background = ComboFoxColors.background;
  static const primary = ComboFoxColors.neonPurple;
  static const secondary = ComboFoxColors.neonBlue;
  static const accent = ComboFoxColors.neonPink;
  static const surface = ComboFoxColors.surface;
  static const surfaceLight = ComboFoxColors.surfaceElevated;
  static const textPrimary = ComboFoxColors.textPrimary;
  static const textSecondary = ComboFoxColors.textSecondary;

  // Input token colors
  static const tokenBackground = Color(0xFF2A2F3A);
  static const buttonA = Color(0xFF4A90D9);
  static const buttonB = Color(0xFF4CAF50);
  static const buttonC = Color(0xFFE53935);
  static const buttonD = Color(0xFFF57C00);

  // Category dot colors
  static const catThrow = Colors.orange;
  static const catCommand = Colors.teal;
  static const catSpecial = Color(0xFF4A90D9);
  static const catDM = Color(0xFFE53935);
  static const catSDM = Color(0xFF9C27B0);
}

class AppGradients {
  AppGradients._();

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ComboFoxColors.neonPurple, ComboFoxColors.neonPink],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ComboFoxColors.neonBlue, ComboFoxColors.neonPurple],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ComboFoxColors.surface, ComboFoxColors.background],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.accent,
      surface: AppColors.surface,
      onPrimary: AppColors.textPrimary,
      onSecondary: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      onError: AppColors.textPrimary,
      outline: AppColors.textSecondary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      indicatorColor: AppColors.primary.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(fontSize: 12, color: AppColors.textSecondary);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.textSecondary);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      dividerHeight: 0,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textSecondary,
      tilePadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.textSecondary.withValues(alpha: 0.15),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Doto',
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Doto',
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Doto',
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(color: AppColors.textPrimary, height: 1.5),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
      labelSmall: TextStyle(color: AppColors.textSecondary, fontSize: 10),
    ),
  );
}
