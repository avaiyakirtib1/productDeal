import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../config/app_config.dart';
import '../localization/language_controller.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';
import 'api_timing.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(sessionStorageProvider);
  final authNotifier = ref.read(authControllerProvider.notifier);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      // On Web, sendTimeout without a request body triggers a Dio warning; avoid on Web.
      sendTimeout: kIsWeb ? null : const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      // Store request start time for timing calculation
      options.extra['requestStartTime'] = DateTime.now().millisecondsSinceEpoch;

      // Inject Language Headers and Params
      final locale = ref.read(languageControllerProvider);
      options.headers['Accept-Language'] = locale.languageCode;
      // Also add query param for backend handling
      options.queryParameters['lang'] = locale.languageCode;

      // Google Play: On Android only, send X-Platform so backend hides tobacco/vape
      // categories and products (Web and iOS are not restricted).
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        options.headers['X-Platform'] = 'android';
      }

      final session = await storage.readSession();
      final token = session?.tokens.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint('⚠️ API call without token: ${options.path}');
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      // Calculate and log request duration
      final startTime =
          response.requestOptions.extra['requestStartTime'] as int?;
      if (startTime != null) {
        final duration = DateTime.now().millisecondsSinceEpoch - startTime;
        final durationSeconds = (duration / 1000).toStringAsFixed(2);
        final method = response.requestOptions.method.toUpperCase();
        final path = response.requestOptions.path;
        final queryParams = response.requestOptions.queryParameters;
        final statusCode = response.statusCode;

        // Build query string for logging
        String queryString = '';
        if (queryParams.isNotEmpty) {
          final queryList =
              queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
          queryString = '?$queryList';
        }

        debugPrint(
          '⏱️ API Response: $method $path$queryString → $statusCode (${duration}ms / ${durationSeconds}s)',
        );
        if (ApiTimingCollector.isEnabled) {
          ApiTimingCollector.record(
            method: method,
            path: path,
            queryString: queryString,
            statusCode: statusCode,
            durationMs: duration,
            success: true,
          );
        }
        // Warn if response time is slow (> 3 seconds)
        if (duration > 3000) {
          debugPrint(
            '⚠️ Slow API Response Warning: $method $path took ${durationSeconds}s (${duration}ms)',
          );
        }
      }
      handler.next(response);
    },
    onError: (error, handler) async {
      // Calculate and log request duration even for errors
      final startTime = error.requestOptions.extra['requestStartTime'] as int?;
      if (startTime != null) {
        final duration = DateTime.now().millisecondsSinceEpoch - startTime;
        final durationSeconds = (duration / 1000).toStringAsFixed(2);
        final method = error.requestOptions.method.toUpperCase();
        final path = error.requestOptions.path;
        final statusCode = error.response?.statusCode ?? 'N/A';

        debugPrint(
          '⏱️ API Error: $method $path → $statusCode (${duration}ms / ${durationSeconds}s)',
        );
        if (ApiTimingCollector.isEnabled) {
          final q = error.requestOptions.queryParameters;
          final qs = q.isEmpty
              ? ''
              : '?${q.entries.map((e) => '${e.key}=${e.value}').join('&')}';
          final msg = error.response?.data is Map<String, dynamic>
              ? (error.response?.data['message'] as String?)
              : error.response?.data?.toString();
          ApiTimingCollector.record(
            method: method,
            path: path,
            queryString: qs,
            statusCode: error.response?.statusCode,
            durationMs: duration,
            success: false,
            errorMessage: msg ?? error.message,
          );
        }
      }

      final statusCode = error.response?.statusCode;
      final alreadyRetried = error.requestOptions.extra['retried'] == true;

      debugPrint('Dio Error: ${error.response?.data}');

      if (statusCode == 401 && !alreadyRetried) {
        final refreshed = await authNotifier.refreshTokens();
        if (refreshed) {
          try {
            final response = await _retryRequest(dio, error.requestOptions);
            return handler.resolve(response);
          } catch (retryError) {
            return handler.reject(retryError as DioException);
          }
        }
      }

      handler.next(error);
    },
  ));

  dio.interceptors.add(LogInterceptor(
    responseBody: false,
    requestBody: true,
    requestHeader: false,
  ));

  return dio;
}, name: 'DioProvider');

Future<Response<dynamic>> _retryRequest(
    Dio dio, RequestOptions requestOptions) {
  final options = Options(
    method: requestOptions.method,
    headers: requestOptions.headers,
    responseType: requestOptions.responseType,
    contentType: requestOptions.contentType,
    receiveTimeout: requestOptions.receiveTimeout,
    sendTimeout: requestOptions.sendTimeout,
    extra: {...requestOptions.extra, 'retried': true},
  );

  return dio.request<dynamic>(
    requestOptions.path,
    data: requestOptions.data,
    queryParameters: requestOptions.queryParameters,
    options: options,
  );
}

ApiException mapDioException(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;
  String? message;

  if (data is Map<String, dynamic>) {
    message = data['message'] as String?;
  } else if (data is String) {
    message = data;
  }

  message ??= error.message ?? 'Something went wrong, please try again.';

  return ApiException(message, statusCode: statusCode);
}
