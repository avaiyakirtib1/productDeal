import 'dart:typed_data';

/// Stub implementation for non-web platforms
Future<bool> downloadFileWeb(Uint8List bytes, String filename) async {
  // This should never be called on non-web platforms
  throw UnsupportedError('downloadFileWeb is only supported on web');
}
