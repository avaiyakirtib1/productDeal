import 'package:flutter/material.dart';

/// Utility class for showing snackbars without stacking
class SnackbarUtils {
  /// Show a success snackbar (green background)
  /// Automatically dismisses any existing snackbar first
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    // Clear any existing snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an error snackbar (red background)
  /// Automatically dismisses any existing snackbar first
  static void showError(BuildContext context, String message,
      {SnackBarAction? action}) {
    if (!context.mounted) return;

    // Clear any existing snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  /// Show an info snackbar (default theme color)
  /// Automatically dismisses any existing snackbar first
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    // Clear any existing snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a warning snackbar (orange background)
  /// Automatically dismisses any existing snackbar first
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;

    // Clear any existing snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
