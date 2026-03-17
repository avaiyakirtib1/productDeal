// ignore_for_file: unused_import, unnecessary_null_comparison, unnecessary_non_null_assertion
import 'dart:io' if (dart.library.html) '';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'upload_service.dart';
import '../utils/file_utils.dart'
    if (dart.library.html) '../utils/file_utils_stub.dart';

/// Helper class for picking images that works on both web and mobile
/// Provides a unified interface for image selection with proper web support
class ImagePickerHelper {
  /// Pick a single image (works on web and mobile)
  /// Returns PickedFileData which can be used with uploadFile
  static Future<PickedFileData?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      if (kIsWeb) {
        // Web: use FilePicker with image filter
        final picker = FilePicker.platform;
        final result = await picker.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final pickedFile = result.files.single;
          if (pickedFile.bytes != null) {
            return PickedFileData(
              bytes: pickedFile.bytes,
              filename: pickedFile.name,
            );
          }
        }
        return null;
      } else {
        // Mobile: use ImagePicker
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );

        if (pickedFile != null) {
          final path = pickedFile.path;
          if (path != null && path.isNotEmpty) {
            return PickedFileData(
              file: createFileFromPath(path),
              filename: pickedFile.name,
            );
          }
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Pick multiple images (works on web and mobile)
  /// Returns `List<PickedFileData>` which can be used with uploadFile
  static Future<List<PickedFileData>> pickMultipleImages({
    int? limit,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      if (kIsWeb) {
        // Web: use FilePicker with image filter
        final picker = FilePicker.platform;
        final result = await picker.pickFiles(
          type: FileType.image,
          allowMultiple: limit == null || limit > 1,
        );

        if (result == null || result.files.isEmpty) {
          return [];
        }

        final List<PickedFileData> files = [];
        for (final pickedFile in result.files) {
          if (pickedFile.bytes != null) {
            files.add(PickedFileData(
              bytes: pickedFile.bytes,
              filename: pickedFile.name,
            ));
          }
        }

        if (limit != null && limit > 0) {
          return files.take(limit).toList();
        }
        return files;
      } else {
        // Mobile: use ImagePicker.pickMultiImage (Android 9+, iOS 14+)
        final picker = ImagePicker();
        final pickedFiles = await picker.pickMultiImage(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
          limit: limit,
        );

        if (pickedFiles.isEmpty) return [];

        return pickedFiles
            .where((x) => x.path != null && x.path!.isNotEmpty)
            .map((x) => PickedFileData(
                  file: createFileFromPath(x.path!),
                  filename: x.name,
                ))
            .toList();
      }
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  /// Pick and crop an image (mobile only - cropping not available on web)
  /// Returns PickedFileData which can be used with uploadFile
  static Future<PickedFileData?> pickAndCropImage({
    ImageSource source = ImageSource.gallery,
    double? aspectRatioX,
    double? aspectRatioY,
    bool circular = false,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      if (kIsWeb) {
        // Web: just pick image (cropping not supported on web)
        return await pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );
      } else {
        // Mobile: pick and crop
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: maxWidth ?? 1920,
          maxHeight: maxHeight ?? 1920,
          imageQuality: imageQuality ?? 85,
        );

        if (pickedFile == null || pickedFile.path == null) {
          return null;
        }

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path!,
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

        if (croppedFile != null && croppedFile.path != null) {
          return PickedFileData(
            file: createFileFromPath(croppedFile.path!),
            filename: croppedFile.path!.split('/').last,
          );
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to pick and crop image: $e');
    }
  }

  /// Pick a video (mobile only - for stories)
  /// Returns PickedFileData which can be used with uploadFile
  static Future<PickedFileData?> pickVideo({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      if (kIsWeb) {
        // Web: use FilePicker with video filter
        final picker = FilePicker.platform;
        final result = await picker.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final pickedFile = result.files.single;
          if (pickedFile.bytes != null) {
            return PickedFileData(
              bytes: pickedFile.bytes,
              filename: pickedFile.name,
            );
          }
        }
        return null;
      } else {
        // Mobile: use ImagePicker
        final picker = ImagePicker();
        final pickedFile = await picker.pickVideo(source: source);

        if (pickedFile != null && pickedFile.path != null) {
          return PickedFileData(
            file: createFileFromPath(pickedFile.path),
            filename: pickedFile.name,
          );
        }
        return null;
      }
    } catch (e) {
      throw Exception('Failed to pick video: $e');
    }
  }
}
