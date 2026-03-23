import 'dart:io';
import 'dart:typed_data';

/// VM / mobile: read bytes from a [dart:io] [File] instance.
Future<Uint8List> readUploadBytesFromIoFile(Object file) async {
  final f = file as File;
  return Uint8List.fromList(await f.readAsBytes());
}

/// VM / mobile: read bytes from a filesystem path.
Future<Uint8List> readUploadBytesFromPath(String path) async {
  return Uint8List.fromList(await File(path).readAsBytes());
}
