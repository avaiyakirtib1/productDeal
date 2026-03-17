import 'dart:io' if (dart.library.html) '';

/// Helper function to create a File object from a path
/// Only works on mobile platforms (not web)
/// Returns dynamic to work with conditional imports
dynamic createFileFromPath(String path) {
  // ignore: avoid_dynamic_calls
  return File(path);
}
