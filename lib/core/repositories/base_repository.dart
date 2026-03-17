import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../networking/api_client.dart';
import '../networking/api_exception.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Base repository class that provides common error handling,
/// especially for authentication errors (401).
///
/// All repositories should extend this class to get consistent
/// auth error handling across the app.
///
/// Note: The global auth listener in app.dart already handles
/// session expiry dialogs, so this class focuses on logging out
/// and letting the global handler show the dialog.
abstract class BaseRepository {
  BaseRepository(Dio dio, this._authNotifier);

  final AuthController _authNotifier;

  /// Handles DioException and converts it to ApiException.
  /// For 401 errors, automatically logs out (the global handler will show dialog).
  ///
  /// Returns the ApiException for the caller to handle if needed.
  Future<ApiException?> handleError(
    DioException error,
    BuildContext? context,
  ) async {
    final apiError = mapDioException(error);

    // Handle 401 (Unauthorized) - session expired or invalid token
    if (apiError.statusCode == 401) {
      // Logout the user - the global listener in app.dart will show the dialog
      await _authNotifier.logout(reason: AuthLogoutReason.sessionExpired);
    }

    return apiError;
  }

  /// Wraps a Dio request with error handling.
  /// Automatically handles 401 errors and shows appropriate dialogs.
  ///
  /// Usage:
  /// ```dart
  /// try {
  ///   final response = await _dio.get('/endpoint');
  ///   return parseResponse(response);
  /// } on DioException catch (error) {
  ///   final apiError = await handleError(error, context);
  ///   throw apiError ?? error;
  /// }
  /// ```
  Future<T> executeRequest<T>({
    required Future<Response> Function() request,
    required T Function(Response) parser,
    BuildContext? context,
  }) async {
    try {
      final response = await request();
      return parser(response);
    } on DioException catch (error) {
      final apiError = await handleError(
        error,
        context != null && context.mounted ? context : null,
      );
      throw apiError ?? error;
    }
  }
}
