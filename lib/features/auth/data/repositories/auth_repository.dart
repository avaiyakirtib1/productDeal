import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_exception.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login(LoginPayload payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/login', data: payload.toJson());
      final data = response.data ?? {};
      return AuthSession(
        user: UserModel.fromJson(data['data'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw ApiException(_resolveMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<AuthSession> register(RegisterPayload payload) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('/auth/register', data: payload.toJson());
      final data = response.data ?? {};
      return AuthSession(
        user: UserModel.fromJson(data['data'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      throw ApiException(_resolveMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      final response = await _dio
          .post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': refreshToken});
      return AuthTokens.fromJson(response.data?['tokens'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException(_resolveMessage(error), statusCode: error.response?.statusCode);
    }
  }

  /// Removes [fcmToken] from the user's device list on the server (multi-device push).
  /// Best-effort: failures are ignored so local logout can finish.
  Future<void> logout({String? fcmToken}) async {
    try {
      final body = <String, dynamic>{};
      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcmToken'] = fcmToken;
      }
      await _dio.post<void>('/auth/logout', data: body);
    } on DioException catch (error) {
      debugPrint('AuthRepository.logout: ${error.message}');
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserModel.fromJson(response.data?['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException(_resolveMessage(error), statusCode: error.response?.statusCode);
    }
  }

  Future<UserModel> updateProfile(UpdateProfilePayload payload) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: payload.toJson(),
      );
      return UserModel.fromJson(response.data?['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiException(_resolveMessage(error), statusCode: error.response?.statusCode);
    }
  }

  String _resolveMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = (data['message'] as String?) ?? (data['debugMessage'] as String?);
      if (message != null && message.isNotEmpty) return message;
      // Try to build message from validation details
      final details = data['details'];
      if (details is Map<String, dynamic>) {
        final fieldErrors = details['fieldErrors'] as Map<String, dynamic>?;
        if (fieldErrors != null && fieldErrors.isNotEmpty) {
          final first = fieldErrors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
      }
    }
    final statusCode = error.response?.statusCode;
    if (statusCode == 409) return 'This email is already registered.';
    if (statusCode == 400) return 'Please check your input and try again.';
    if (statusCode != null && statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Please check your network.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect. Please check your internet connection.';
    }
    return error.message ?? 'Something went wrong, please try again.';
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
  name: 'AuthRepositoryProvider',
);
