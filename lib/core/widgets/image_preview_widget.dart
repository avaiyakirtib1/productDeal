import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/upload_service.dart';

/// A widget that displays an image preview from PickedFileData
/// Works on both web (bytes) and mobile (file)
class ImagePreviewWidget extends StatelessWidget {
  final PickedFileData fileData;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ImagePreviewWidget({
    super.key,
    required this.fileData,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web: use bytes
      if (fileData.bytes != null) {
        return Image.memory(
          Uint8List.fromList(fileData.bytes!),
          fit: fit,
          width: width,
          height: height,
        );
      }
      return const SizedBox.shrink();
    } else {
      // Mobile: use file
      final file = fileData.fileAsFile;
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
      );
    }
  }
}
