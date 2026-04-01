import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// CPS2-Inspired Arcade Theme
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  static const background = Color(0xFF0B0F1A);
  static const primary = Color(0xFF6A00FF);
  static const secondary = Color(0xFF00E5FF);
  static const accent = Color(0xFFFF3B3B);
  static const surface = Color(0xFF121826);
  static const surfaceLight = Color(0xFF1A2036);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA0A8C0);

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
    colors: [AppColors.primary, Color(0xFF1A3AF5)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3AF5), AppColors.secondary],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surface, AppColors.background],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.3),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          );
        }
        return const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.secondary);
        }
        return const IconThemeData(color: AppColors.textSecondary);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.secondary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.secondary,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
        borderSide: const BorderSide(
          color: AppColors.secondary,
          width: 1.5,
        ),
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
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
      ),
    ),
  );
}
