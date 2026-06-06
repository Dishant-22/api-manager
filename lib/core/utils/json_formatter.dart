import 'dart:convert';

class JsonFormatter {
  JsonFormatter._();

  static String prettyPrint(String input) {
    try {
      final dynamic parsed = json.decode(input);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(parsed);
    } catch (_) {
      return input;
    }
  }

  static bool isValidJson(String input) {
    try {
      json.decode(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String minify(String input) {
    try {
      final dynamic parsed = json.decode(input);
      return json.encode(parsed);
    } catch (_) {
      return input;
    }
  }

  static dynamic parse(String input) {
    try {
      return json.decode(input);
    } catch (_) {
      return null;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDuration(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  /// Detect content type from response headers and body.
  static String detectLanguage(String? contentType, String body) {
    if (contentType != null) {
      if (contentType.contains('json')) return 'json';
      if (contentType.contains('xml')) return 'xml';
      if (contentType.contains('html')) return 'html';
      if (contentType.contains('javascript')) return 'javascript';
      if (contentType.contains('css')) return 'css';
    }
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'json';
    if (trimmed.startsWith('<')) return 'xml';
    return 'plaintext';
  }
}
