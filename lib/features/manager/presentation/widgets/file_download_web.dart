// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web-specific implementation for file downloads
Future<bool> downloadFileWeb(Uint8List bytes, String filename) async {
  try {
    // Create a blob from the bytes
    final blob = html.Blob([bytes], 'text/csv');

    // Create a URL for the blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create a temporary anchor element and trigger download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    // Clean up the URL
    html.Url.revokeObjectUrl(url);

    return true;
  } catch (e) {
    return false;
  }
}
