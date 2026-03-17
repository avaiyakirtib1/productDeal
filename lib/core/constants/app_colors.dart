import 'package:flutter/material.dart';

/// App color constants based on the design system
/// Colors converted from HSL to RGB
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF3CB5DC); // hsl(195, 92%, 42%)
  static const Color primaryLight = Color(0xFF5FC5E8); // hsl(195, 100%, 55%)
  static const Color primaryDark = Color(0xFF2A9FC4); // darker variant

  // Secondary colors
  static const Color secondary = Color(0xFFFF8C42); // hsl(27, 96%, 61%)
  static const Color secondaryLight = Color(0xFFFFA366); // hsl(27, 96%, 75%)

  // Background colors
  static const Color background = Color(0xFFF8FAFC); // hsl(210, 40%, 98%)
  static const Color foreground = Color(0xFF1A1F2E); // hsl(222, 47%, 11%)

  // Card colors
  static const Color card = Color(0xFFFFFFFF); // hsl(0, 0%, 100%)
  static const Color cardForeground = Color(0xFF1A1F2E); // hsl(222, 47%, 11%)

  // Popover colors
  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF1A1F2E);

  // Muted colors
  static const Color muted = Color(0xFFE8EDF2); // hsl(210, 40%, 96%)
  static const Color mutedForeground = Color(0xFF6B7280); // hsl(215, 16%, 47%)

  // Accent colors
  static const Color accent = Color(0xFFE0F7FA); // hsl(195, 100%, 95%)
  static const Color accentForeground = Color(0xFF3CB5DC); // hsl(195, 92%, 42%)

  // Semantic colors
  static const Color success = Color(0xFF16A34A); // hsl(142, 76%, 36%)
  static const Color successForeground = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFF59E0B); // hsl(38, 92%, 50%)
  static const Color warningForeground = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444); // hsl(0, 84%, 60%)
  static const Color errorForeground = Color(0xFFFAFAFA); // hsl(0, 0%, 98%)

  // Border and input colors
  static const Color border = Color(0xFFDEE4EA); // hsl(214, 32%, 91%)
  static const Color input = Color(0xFFDEE4EA);

  // Ring color (focus indicator)
  static const Color ring = Color(0xFF3CB5DC); // hsl(195, 92%, 42%)

  // Text colors
  static const Color textPrimary = Color(0xFF1A1F2E); // foreground
  static const Color textSecondary = Color(0xFF6B7280); // mutedForeground
  static const Color textMuted = Color(0xFF9CA3AF);

  // Neutral grays (for compatibility)
  static Color get neutral100 => muted;
  static Color get neutral200 => border;
  static Color get neutral300 => mutedForeground;

  // Gradient helpers
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
}
