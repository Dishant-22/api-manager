import '../../../features/requests/models/api_request.dart';
import '../../../features/requests/models/key_value_pair.dart';
import '../../../features/requests/models/request_body.dart';
import '../../../features/requests/models/auth_config.dart';

class CurlParser {
  CurlParser._();

  static ApiRequest? parse(String curlCommand) {
    try {
      final cleaned = curlCommand
          .replaceAll('\\\n', ' ')
          .replaceAll('\\\r\n', ' ')
          .trim();

      final tokens = _tokenize(cleaned);
      if (tokens.isEmpty || tokens[0].toLowerCase() != 'curl') return null;

      String method = 'GET';
      String url = '';
      final headers = <KeyValuePair>[];
      String? bodyData;

      int i = 1;
      while (i < tokens.length) {
        final token = tokens[i];
        switch (token) {
          case '-X':
          case '--request':
            i++;
            if (i < tokens.length) method = tokens[i].toUpperCase();
          case '-H':
          case '--header':
            i++;
            if (i < tokens.length) {
              final parts = tokens[i].split(':');
              if (parts.length >= 2) {
                headers.add(KeyValuePair(
                  key: parts[0].trim(),
                  value: parts.sublist(1).join(':').trim(),
                ));
              }
            }
          case '-d':
          case '--data':
          case '--data-raw':
          case '--data-ascii':
            i++;
            if (i < tokens.length) {
              bodyData = tokens[i];
              if (method == 'GET') method = 'POST';
            }
          case '--compressed':
            break;
          case '-L':
          case '--location':
            break;
          default:
            if (!token.startsWith('-') && url.isEmpty) {
              url = token.replaceAll("'", '').replaceAll('"', '');
            }
        }
        i++;
      }

      if (url.isEmpty) return null;

      final uri = Uri.tryParse(url);
      final queryParams = <KeyValuePair>[];
      if (uri != null) {
        for (final entry in uri.queryParameters.entries) {
          queryParams.add(KeyValuePair(key: entry.key, value: entry.value));
        }
        url = uri.replace(queryParameters: {}).toString();
        if (url.endsWith('?')) url = url.substring(0, url.length - 1);
      }

      RequestBody? requestBody;
      if (bodyData != null) {
        requestBody = RequestBody(type: BodyType.rawJson, rawContent: bodyData);
      }

      return ApiRequest(
        method: method,
        url: url,
        headers: headers,
        queryParams: queryParams,
        body: requestBody ?? const RequestBody(type: BodyType.none),
        auth: const AuthConfig(type: AuthType.none),
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (ch == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      } else if (ch == ' ' && !inSingleQuote && !inDoubleQuote) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }
}
