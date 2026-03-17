import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/api_client.dart' as api_client;
import '../models/account_models.dart';

class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  Future<List<CategorizedDocument>> getDocuments() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/account/documents');
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      final list = data['documents'] as List<dynamic>? ?? [];
      return list
          .map((e) => CategorizedDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<void> removeDocument(String documentUrl) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/account/verification-documents/remove',
        data: {'documentUrl': documentUrl},
      );
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<AccountStatus> getStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/account/status');
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AccountStatus.fromJson(data);
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<DocumentUploadResponse> uploadDocuments(
      List<String> documentUrls) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/account/verification-documents',
        data: {'documentUrls': documentUrls},
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return DocumentUploadResponse.fromJson(data);
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<DocumentUploadResponse> uploadCategorizedDocument({
    required String documentUrl,
    required String documentType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/account/verification-documents',
        data: {
          'documentUrl': documentUrl,
          'documentType': documentType,
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return DocumentUploadResponse.fromJson(data);
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }

  Future<DeletionRequestResponse> requestAccountDeletion({
    required String email,
    String? reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/account-deletion/request',
        data: {
          'email': email,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      final message = response.data?['message'] as String?;
      return DeletionRequestResponse.fromJson({
        ...data,
        if (message != null) 'message': message,
      });
    } on DioException catch (error) {
      throw api_client.mapDioException(error);
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(dioProvider));
});
