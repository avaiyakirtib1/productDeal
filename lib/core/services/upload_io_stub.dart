import 'dart:typed_data';

/// Web stub — never call on web; [PickedFileData] should use bytes instead.
Future<Uint8List> readUploadBytesFromIoFile(Object file) async {
  throw UnsupportedError('readUploadBytesFromIoFile is not supported on web');
}

/// Web stub — never call on web.
Future<Uint8List> readUploadBytesFromPath(String path) async {
  throw UnsupportedError('readUploadBytesFromPath is not supported on web');
}
