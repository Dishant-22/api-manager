extension StringExtensions on String {
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  bool get isValidJson {
    try {
      // ignore: prefer_const_declarations
      final s = trim();
      return (s.startsWith('{') && s.endsWith('}')) ||
          (s.startsWith('[') && s.endsWith(']'));
    } catch (_) {
      return false;
    }
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String toDisplayUrl() {
    try {
      final uri = Uri.parse(this);
      return '${uri.host}${uri.path}';
    } catch (_) {
      return truncate(50);
    }
  }

  /// Resolve {{variable}} placeholders with values from a map.
  String resolveVariables(Map<String, String> variables) {
    var result = this;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// Extract all {{variable}} names from the string.
  List<String> get templateVariables {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    return regex.allMatches(this).map((m) => m.group(1)!).toList();
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';
}
