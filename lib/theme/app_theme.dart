import 'package:flutter/material.dart';
import 'package:traavaalay/theme/app_colors.dart';

class AppTheme {
  static ThemeData get dark => darkTheme;
  static ThemeData get light => darkTheme;
  static ThemeData get lightTheme => darkTheme;

  static ThemeData get darkTheme {
    const textTheme = TextTheme(
      headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textMuted),
      labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
    );

    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.primary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.textPrimary,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.18),
      onSecondaryContainer: AppColors.secondary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: colorScheme,
      textTheme: textTheme,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      splashColor: AppColors.secondary.withValues(alpha: 0.08),
      highlightColor: AppColors.secondary.withValues(alpha: 0.06),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        selectedColor: AppColors.secondary.withValues(alpha: 0.2),
        disabledColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.secondary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.secondary,
        dividerColor: AppColors.border,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.secondary),
    );

    return base;
  }
}
