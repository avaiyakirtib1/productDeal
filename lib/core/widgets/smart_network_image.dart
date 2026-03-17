import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// An image widget that handles both HTTP URLs and data URIs (base64).
/// Use this instead of CachedNetworkImage when the URL may be a data: URI,
/// which CachedNetworkImage cannot handle (causes "No host specified in URI").
class SmartNetworkImage extends StatelessWidget {
  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  static bool _isDataUri(String url) =>
      url.startsWith('data:image') && url.contains('base64,');

  static Uint8List? _decodeDataUri(String dataUri) {
    try {
      final base64Index = dataUri.indexOf('base64,');
      if (base64Index == -1) return null;
      final base64Data = dataUri.substring(base64Index + 7);
      return Uint8List.fromList(base64Decode(base64Data));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildError(context);
    }

    if (_isDataUri(imageUrl)) {
      final bytes = _decodeDataUri(imageUrl);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildError(context),
        );
      }
      return _buildError(context);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder ?? (_, __) => _defaultPlaceholder(context),
      errorWidget: errorWidget ?? (_, __, ___) => _buildError(context),
    );
  }

  Widget _defaultPlaceholder(BuildContext context) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  Widget _buildError(BuildContext context) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      );
}

/// Provider for CachedNetworkImageProvider that handles data URIs.
/// Use when you need ImageProvider (e.g. for CircleAvatar.backgroundImage).
ImageProvider? smartImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (SmartNetworkImage._isDataUri(url)) {
    final bytes = SmartNetworkImage._decodeDataUri(url);
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }
  return CachedNetworkImageProvider(url);
}
