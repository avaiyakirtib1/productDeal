import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../networking/api_client.dart';
import '../utils/file_utils.dart'
    if (dart.library.html) '../utils/file_utils_stub.dart';
import 'upload_io.dart' if (dart.library.html) 'upload_io_stub.dart';

// Type alias for File that works on both platforms
// On web, this will be dynamic, on mobile it will be File from dart:io
typedef PlatformFile = dynamic;

/// A class to hold file data that works on both web and mobile
class PickedFileData {
  final PlatformFile? file; // For mobile platforms (File from dart:io)
  final List<int>? bytes; // For web platform
  final String filename;

  PickedFileData({
    this.file,
    this.bytes,
    required this.filename,
  }) : assert(
          (file != null && bytes == null) || (file == null && bytes != null),
          'Either file or bytes must be provided, but not both',
        );

  bool get isWeb => bytes != null;

  // Helper to get File on mobile (only call when !isWeb)
  dynamic get fileAsFile {
    if (kIsWeb) {
      throw UnsupportedError('File is not available on web');
    }
    // ignore: avoid_dynamic_calls
    return file;
  }
}

class UploadService {
  UploadService(this._dio);

  final Dio _dio;

  static String _guessImageContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Future<Uint8List> _readUploadBytes({
    required PickedFileData? fileData,
    required PlatformFile? file,
  }) async {
    if (fileData != null) {
      if (fileData.isWeb) {
        return Uint8List.fromList(fileData.bytes!);
      }
      return readUploadBytesFromIoFile(fileData.fileAsFile);
    }
    if (file != null && !kIsWeb) {
      // ignore: avoid_dynamic_calls
      final fPath = (file as dynamic).path as String;
      return readUploadBytesFromPath(fPath);
    }
    throw Exception('Either file or fileData must be provided');
  }

  /// Client → Supabase signed URL (bypasses Vercel multipart proxy).
  Future<String> _uploadViaPresignedUrl({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String contentType,
  }) async {
    final presigned = await getPresignedUrl(
      filename: fileName,
      contentType: contentType,
      folder: folder,
    );
    final uploadUrl = presigned['uploadUrl'] as String?;
    final publicUrl = presigned['publicUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('Presigned upload: missing uploadUrl');
    }
    if (publicUrl == null || publicUrl.isEmpty) {
      throw Exception('Presigned upload: missing publicUrl');
    }

    // Do not use [_dio]: ApiClient injects Authorization + `lang` on every request,
    // which breaks Supabase signed URLs and can cause upload failures.
    final direct = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: kIsWeb ? null : const Duration(seconds: 30),
      ),
    );
    await direct.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: <String, dynamic>{
          Headers.contentTypeHeader: contentType,
        },
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    return publicUrl;
  }

  /// Upload a file directly to the server
  /// Returns the public URL of the uploaded file
  /// Accepts either a File (mobile) or PickedFileData (web/mobile compatible)
  Future<String> uploadFile({
    PlatformFile? file,
    PickedFileData? fileData,
    required String folder, // 'products', 'categories', 'stories', 'profiles'
  }) async {
    try {
      MultipartFile multipartFile;
      String fileName;

      if (fileData != null) {
        // Use PickedFileData (works for both web and mobile)
        if (fileData.isWeb) {
          // Web: use bytes
          multipartFile = MultipartFile.fromBytes(
            fileData.bytes!,
            filename: fileData.filename,
          );
          fileName = fileData.filename;
        } else {
          // Mobile: use file
          final file = fileData.fileAsFile;
          multipartFile = await MultipartFile.fromFile(
            file.path,
            filename: fileData.filename,
          );
          fileName = fileData.filename;
        }
      } else if (file != null && !kIsWeb) {
        // Legacy support: direct File (mobile only)
        // ignore: avoid_dynamic_calls
        final filePath = (file as dynamic).path as String;
        fileName = filePath.split('/').last;
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      } else {
        throw Exception('Either file or fileData must be provided');
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        'folder': folder,
      });

      try {
        final response = await _dio.post<Map<String, dynamic>>(
          '/upload',
          data: formData,
        );

        final url = response.data?['data']?['url'] as String?;
        if (url == null) {
          throw Exception('Upload failed: No URL returned');
        }
        return url;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 500 || code == 502 || code == 503) {
          final bytes = await _readUploadBytes(
            fileData: fileData,
            file: file,
          );
          final ct = _guessImageContentType(fileName);
          return _uploadViaPresignedUrl(
            bytes: bytes,
            fileName: fileName,
            folder: folder,
            contentType: ct,
          );
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Get a presigned URL for client-side upload
  Future<Map<String, dynamic>> getPresignedUrl({
    required String filename,
    required String contentType,
    required String folder,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/upload/presigned-url',
        queryParameters: {
          'filename': filename,
          'contentType': contentType,
          'folder': folder,
        },
      );
      return response.data?['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      throw Exception('Failed to get presigned URL: $e');
    }
  }

  /// Pick an image from gallery or camera
  /// DEPRECATED: Use ImagePickerHelper.pickImage() instead for web compatibility
  @Deprecated('Use ImagePickerHelper.pickImage() for web compatibility')
  Future<PlatformFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (pickedFile != null && !kIsWeb) {
        return createFileFromPath(pickedFile.path) as PlatformFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick and crop an image (useful for profile images that need to be square)
  /// DEPRECATED: Use ImagePickerHelper.pickAndCropImage() instead for web compatibility
  @Deprecated('Use ImagePickerHelper.pickAndCropImage() for web compatibility')
  Future<PlatformFile?> pickAndCropImage({
    ImageSource source = ImageSource.gallery,
    double? aspectRatioX,
    double? aspectRatioY,
    bool circular = false,
  }) async {
    try {
      final imageFile = await pickImage(source: source);
      if (imageFile == null) return null;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: aspectRatioX != null && aspectRatioY != null
            ? CropAspectRatio(ratioX: aspectRatioX, ratioY: aspectRatioY)
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: aspectRatioX != null && aspectRatioY != null,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled:
                aspectRatioX != null && aspectRatioY != null,
            aspectRatioLockDimensionSwapEnabled: false,
          ),
        ],
      );

      if (croppedFile != null && !kIsWeb) {
        return createFileFromPath(croppedFile.path) as PlatformFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  /// Pick a document (PDF, images) for verification
  /// Returns PickedFileData which works on both web and mobile
  Future<PickedFileData?> pickDocument() async {
    try {
      final picker = FilePicker.platform;
      final result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final pickedFile = result.files.single;

      if (kIsWeb) {
        // Web: use bytes
        if (pickedFile.bytes != null) {
          return PickedFileData(
            bytes: pickedFile.bytes,
            filename: pickedFile.name,
          );
        }
        return null;
      } else {
        // Mobile: use path
        if (pickedFile.path != null) {
          return PickedFileData(
            file: createFileFromPath(pickedFile.path!) as PlatformFile,
            filename: pickedFile.name,
          );
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to pick document: $e');
    }
  }

  /// Pick multiple documents (PDF, images) for verification
  /// Returns `List<PickedFileData>` which works on both web and mobile
  Future<List<PickedFileData>> pickMultipleDocuments({int? limit}) async {
    try {
      final picker = FilePicker.platform;
      final result = await picker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: limit == null || limit > 1,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final List<PickedFileData> files = [];

      for (final pickedFile in result.files) {
        if (kIsWeb) {
          // Web: use bytes
          if (pickedFile.bytes != null) {
            files.add(PickedFileData(
              bytes: pickedFile.bytes,
              filename: pickedFile.name,
            ));
          }
        } else {
          // Mobile: use path
          if (pickedFile.path != null) {
            files.add(PickedFileData(
              file: createFileFromPath(pickedFile.path!) as PlatformFile,
              filename: pickedFile.name,
            ));
          }
        }
      }

      if (limit != null && limit > 0) {
        return files.take(limit).toList();
      }
      return files;
    } catch (e) {
      throw Exception('Failed to pick documents: $e');
    }
  }
}

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.watch(dioProvider));
});
