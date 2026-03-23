import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Runs on a background isolate via [compute]. Resize + JPEG encode for uploads.
Uint8List preprocessDealImageForUpload(Uint8List raw) {
  try {
    if (raw.isEmpty) return raw;
    final image = img.decodeImage(raw);
    if (image == null) return raw;

    const maxSide = 2048;
    img.Image processed = image;
    if (image.width > maxSide || image.height > maxSide) {
      if (image.width >= image.height) {
        processed = img.copyResize(image, width: maxSide);
      } else {
        processed = img.copyResize(image, height: maxSide);
      }
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 85));
  } catch (_) {
    return raw;
  }
}
