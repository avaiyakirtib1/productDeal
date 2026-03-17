import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme(TextTheme baseTextTheme) {
    // Create a custom ColorScheme based on the design system
    final colorScheme = ColorScheme.light(
      // Primary colors
      primary: AppColors.primary,
      onPrimary: AppColors.successForeground,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: AppColors.accentForeground,

      // Secondary colors
      secondary: AppColors.secondary,
      onSecondary: AppColors.successForeground,
      secondaryContainer: AppColors.secondaryLight.withValues(alpha: 0.2),
      onSecondaryContainer: AppColors.secondary,

      // Tertiary (can use accent)
      tertiary: AppColors.accentForeground,
      onTertiary: AppColors.accent,

      // Error colors
      error: AppColors.error,
      onError: AppColors.errorForeground,
      errorContainer: AppColors.error.withValues(alpha: 0.1),
      onErrorContainer: AppColors.error,

      // Surface colors (background/onBackground deprecated, use surface/onSurface)
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      surfaceContainerHighest: AppColors.muted,
      onSurfaceVariant: AppColors.mutedForeground,

      // Outline colors
      outline: AppColors.border,
      outlineVariant: AppColors.input,

      // Shadow
      shadow: AppColors.foreground.withValues(alpha: 0.08),
      scrim: AppColors.foreground.withValues(alpha: 0.32),

      // Inverse colors
      inverseSurface: AppColors.foreground,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.primaryLight,
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      brightness: Brightness.light,

      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.successForeground,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.successForeground),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark, // For iOS
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: AppColors.foreground.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // --radius: .75rem
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.successForeground,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: baseTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.successForeground,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.successForeground,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.mutedForeground,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.mutedForeground,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.muted,
        deleteIconColor: AppColors.mutedForeground,
        disabledColor: AppColors.muted.withValues(alpha: 0.5),
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.accentForeground,
        ),
        brightness: Brightness.light,
        elevation: 0,
        pressElevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.muted,
        circularTrackColor: AppColors.muted,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.successForeground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: baseTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.foreground,
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.background,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.muted;
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.successForeground),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),
    );
  }
}
