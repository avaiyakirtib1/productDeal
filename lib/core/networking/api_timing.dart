import 'package:flutter/foundation.dart';

/// Record for a single API request timing (for detailed analysis).
class ApiTimingRecord {
  const ApiTimingRecord({
    required this.method,
    required this.path,
    required this.queryString,
    required this.statusCode,
    required this.durationMs,
    required this.success,
    this.errorMessage,
  });

  final String method;
  final String path;
  final String queryString;
  final int? statusCode;
  final int durationMs;
  final bool success;
  final String? errorMessage;

  String get fullPath => queryString.isEmpty ? path : '$path$queryString';

  double get durationSeconds => durationMs / 1000.0;

  @override
  String toString() =>
      '${success ? "✓" : "✗"} $method $fullPath → ${statusCode ?? "N/A"} '
      '(${durationMs}ms / ${durationSeconds.toStringAsFixed(2)}s)'
      '${errorMessage != null ? " — $errorMessage" : ""}';
}

/// Collects API timings when enabled; use in tests for detailed analysis.
class ApiTimingCollector {
  ApiTimingCollector._();

  static final List<ApiTimingRecord> _records = [];
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  static void enable() {
    _enabled = true;
    _records.clear();
  }

  static void disable() {
    _enabled = false;
  }

  static void record({
    required String method,
    required String path,
    String queryString = '',
    int? statusCode,
    required int durationMs,
    required bool success,
    String? errorMessage,
  }) {
    if (!_enabled) return;
    _records.add(ApiTimingRecord(
      method: method,
      path: path,
      queryString: queryString,
      statusCode: statusCode,
      durationMs: durationMs,
      success: success,
      errorMessage: errorMessage,
    ));
  }

  static List<ApiTimingRecord> getRecords() =>
      List<ApiTimingRecord>.unmodifiable(_records);

  static void clear() {
    _records.clear();
  }

  /// Prints a detailed analysis report to debug console.
  static void printReport({String? title}) {
    if (title != null && title.isNotEmpty) {
      debugPrint('');
      debugPrint('═' * 60);
      debugPrint(title);
      debugPrint('═' * 60);
    }
    debugPrint('');
    debugPrint('API TIMING ANALYSIS (detailed)');
    debugPrint('─' * 60);
    if (_records.isEmpty) {
      debugPrint('No API calls recorded.');
      debugPrint('─' * 60);
      return;
    }
    int totalMs = 0;
    for (var i = 0; i < _records.length; i++) {
      final r = _records[i];
      totalMs += r.durationMs;
      debugPrint('${i + 1}. $r');
    }
    debugPrint('─' * 60);
    debugPrint(
      'TOTAL: ${_records.length} request(s) | '
      '${totalMs}ms (${(totalMs / 1000).toStringAsFixed(2)}s)',
    );
    debugPrint('═' * 60);
    debugPrint('');
  }

  static String reportAsString({String? title}) {
    final buffer = StringBuffer();
    if (title != null && title.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('═' * 60);
      buffer.writeln(title);
      buffer.writeln('═' * 60);
    }
    buffer.writeln('');
    buffer.writeln('API TIMING ANALYSIS (detailed)');
    buffer.writeln('─' * 60);
    if (_records.isEmpty) {
      buffer.writeln('No API calls recorded.');
      buffer.writeln('─' * 60);
      return buffer.toString();
    }
    int totalMs = 0;
    for (var i = 0; i < _records.length; i++) {
      final r = _records[i];
      totalMs += r.durationMs;
      buffer.writeln('${i + 1}. $r');
    }
    buffer.writeln('─' * 60);
    buffer.writeln(
      'TOTAL: ${_records.length} request(s) | '
      '${totalMs}ms (${(totalMs / 1000).toStringAsFixed(2)}s)',
    );
    buffer.writeln('═' * 60);
    buffer.writeln('');
    return buffer.toString();
  }
}
