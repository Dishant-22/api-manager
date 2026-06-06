import 'dart:convert';
import '../../features/requests/models/api_request.dart';
import '../../features/requests/models/request_body.dart';
import '../../features/requests/models/auth_config.dart';

enum CodeLanguage {
  curl,
  dartDio,
  jsFetch,
  jsAxios,
  pythonRequests,
  javaOkHttp,
}

extension CodeLanguageExtension on CodeLanguage {
  String get displayName {
    switch (this) {
      case CodeLanguage.curl:
        return 'cURL';
      case CodeLanguage.dartDio:
        return 'Dart (Dio)';
      case CodeLanguage.jsFetch:
        return 'JavaScript (Fetch)';
      case CodeLanguage.jsAxios:
        return 'JavaScript (Axios)';
      case CodeLanguage.pythonRequests:
        return 'Python (Requests)';
      case CodeLanguage.javaOkHttp:
        return 'Java (OkHttp)';
    }
  }
}

class CodeGenerator {
  CodeGenerator._();

  static String generate(ApiRequest request, CodeLanguage language) {
    switch (language) {
      case CodeLanguage.curl:
        return _toCurl(request);
      case CodeLanguage.dartDio:
        return _toDartDio(request);
      case CodeLanguage.jsFetch:
        return _toJsFetch(request);
      case CodeLanguage.jsAxios:
        return _toJsAxios(request);
      case CodeLanguage.pythonRequests:
        return _toPythonRequests(request);
      case CodeLanguage.javaOkHttp:
        return _toJavaOkHttp(request);
    }
  }

  static String _toCurl(ApiRequest req) {
    final buf = StringBuffer('curl -X ${req.method}');

    // URL with query params
    final uri = _buildUri(req);
    buf.write(" \\\n  '${uri.toString()}'");

    // Headers
    for (final h in req.headers.where((h) => h.enabled && h.key.isNotEmpty)) {
      buf.write(" \\\n  -H '${h.key}: ${h.value}'");
    }

    // Auth
    _appendCurlAuth(buf, req.auth);

    // Body
    if (req.body.hasContent) {
      switch (req.body.type) {
        case BodyType.rawJson:
          buf.write(" \\\n  -H 'Content-Type: application/json'");
          buf.write(" \\\n  -d '${req.body.rawContent}'");
        case BodyType.formUrlEncoded:
          final fields = req.body.urlEncodedFields
              .where((f) => f.enabled && f.key.isNotEmpty)
              .map((f) => '${Uri.encodeComponent(f.key)}=${Uri.encodeComponent(f.value)}')
              .join('&');
          buf.write(" \\\n  --data-urlencode '$fields'");
        case BodyType.rawText:
          buf.write(" \\\n  -d '${req.body.rawContent}'");
        default:
          break;
      }
    }

    return buf.toString();
  }

  static void _appendCurlAuth(StringBuffer buf, AuthConfig auth) {
    switch (auth.type) {
      case AuthType.bearerToken:
        if (auth.bearerToken?.isNotEmpty == true) {
          buf.write(" \\\n  -H 'Authorization: Bearer ${auth.bearerToken}'");
        }
      case AuthType.basicAuth:
        if (auth.username?.isNotEmpty == true) {
          buf.write(" \\\n  -u '${auth.username}:${auth.password ?? ''}'");
        }
      case AuthType.apiKey:
        if (auth.apiKeyName?.isNotEmpty == true && auth.apiKeyValue?.isNotEmpty == true) {
          if (auth.apiKeyIn == 'header') {
            buf.write(" \\\n  -H '${auth.apiKeyName}: ${auth.apiKeyValue}'");
          }
        }
      default:
        break;
    }
  }

  static String _toDartDio(ApiRequest req) {
    final buf = StringBuffer();
    buf.writeln("import 'package:dio/dio.dart';");
    buf.writeln();
    buf.writeln('final dio = Dio();');
    buf.writeln();
    buf.writeln('Future<void> makeRequest() async {');
    buf.writeln('  try {');

    // Params
    final params = req.queryParams.where((p) => p.enabled && p.key.isNotEmpty);
    if (params.isNotEmpty) {
      buf.writeln('    final queryParameters = {');
      for (final p in params) {
        buf.writeln("      '${p.key}': '${p.value}',");
      }
      buf.writeln('    };');
    }

    // Headers
    final headers = req.headers.where((h) => h.enabled && h.key.isNotEmpty);
    if (headers.isNotEmpty) {
      buf.writeln('    final headers = {');
      for (final h in headers) {
        buf.writeln("      '${h.key}': '${h.value}',");
      }
      _appendDioAuthHeaders(buf, req.auth);
      buf.writeln('    };');
    }

    // Body
    final bodyArg = req.body.hasContent ? _dartBodyString(req.body) : '';

    buf.write(
        '    final response = await dio.${req.method.toLowerCase()}(\n      \'${req.url}\'');
    if (params.isNotEmpty) buf.write(',\n      queryParameters: queryParameters');
    if (headers.isNotEmpty) buf.write(',\n      options: Options(headers: headers)');
    if (bodyArg.isNotEmpty) buf.write(',\n      data: $bodyArg');
    buf.writeln(',\n    );');
    buf.writeln('    print(response.data);');
    buf.writeln('  } on DioException catch (e) {');
    buf.writeln('    print(e.message);');
    buf.writeln('  }');
    buf.writeln('}');
    return buf.toString();
  }

  static void _appendDioAuthHeaders(StringBuffer buf, AuthConfig auth) {
    switch (auth.type) {
      case AuthType.bearerToken:
        if (auth.bearerToken?.isNotEmpty == true) {
          buf.writeln("      'Authorization': 'Bearer ${auth.bearerToken}',");
        }
      default:
        break;
    }
  }

  static String _dartBodyString(RequestBody body) {
    switch (body.type) {
      case BodyType.rawJson:
        return "'''${body.rawContent}'''";
      case BodyType.formUrlEncoded:
        final map = {
          for (final f in body.urlEncodedFields.where((f) => f.enabled && f.key.isNotEmpty))
            f.key: f.value,
        };
        return jsonEncode(map);
      default:
        return "'''${body.rawContent}'''";
    }
  }

  static String _toJsFetch(ApiRequest req) {
    final uri = _buildUri(req);
    final buf = StringBuffer();
    buf.writeln("const url = '${uri.toString()}';");
    buf.writeln('const options = {');
    buf.writeln("  method: '${req.method}',");

    final headers = <String, String>{};
    for (final h in req.headers.where((h) => h.enabled && h.key.isNotEmpty)) {
      headers[h.key] = h.value;
    }
    if (req.body.hasContent) {
      headers['Content-Type'] = req.body.contentType;
    }

    if (headers.isNotEmpty) {
      buf.writeln('  headers: {');
      for (final e in headers.entries) {
        buf.writeln("    '${e.key}': '${e.value}',");
      }
      buf.writeln('  },');
    }

    if (req.body.hasContent && req.body.rawContent != null) {
      buf.writeln('  body: JSON.stringify(${req.body.rawContent}),');
    }

    buf.writeln('};');
    buf.writeln();
    buf.writeln('fetch(url, options)');
    buf.writeln('  .then(res => res.json())');
    buf.writeln('  .then(data => console.log(data))');
    buf.writeln('  .catch(err => console.error(err));');
    return buf.toString();
  }

  static String _toJsAxios(ApiRequest req) {
    final uri = _buildUri(req);
    final buf = StringBuffer();
    buf.writeln("import axios from 'axios';");
    buf.writeln();
    buf.writeln('const config = {');
    buf.writeln("  method: '${req.method.toLowerCase()}',");
    buf.writeln("  url: '${uri.toString()}',");

    final headers = <String, String>{};
    for (final h in req.headers.where((h) => h.enabled && h.key.isNotEmpty)) {
      headers[h.key] = h.value;
    }
    if (headers.isNotEmpty) {
      buf.writeln('  headers: {');
      for (final e in headers.entries) {
        buf.writeln("    '${e.key}': '${e.value}',");
      }
      buf.writeln('  },');
    }

    if (req.body.hasContent) {
      buf.writeln("  data: ${req.body.rawContent ?? '{}'},");
    }

    buf.writeln('};');
    buf.writeln();
    buf.writeln('axios(config)');
    buf.writeln('  .then(response => console.log(response.data))');
    buf.writeln('  .catch(error => console.error(error));');
    return buf.toString();
  }

  static String _toPythonRequests(ApiRequest req) {
    final buf = StringBuffer();
    buf.writeln('import requests');
    buf.writeln();
    buf.writeln("url = '${req.url}'");

    final params = req.queryParams.where((p) => p.enabled && p.key.isNotEmpty);
    if (params.isNotEmpty) {
      buf.writeln('params = {');
      for (final p in params) {
        buf.writeln("    '${p.key}': '${p.value}',");
      }
      buf.writeln('}');
    }

    final headers = req.headers.where((h) => h.enabled && h.key.isNotEmpty);
    if (headers.isNotEmpty) {
      buf.writeln('headers = {');
      for (final h in headers) {
        buf.writeln("    '${h.key}': '${h.value}',");
      }
      buf.writeln('}');
    }

    if (req.body.hasContent) {
      buf.writeln("data = '''${req.body.rawContent}'''");
    }

    buf.write(
        'response = requests.${req.method.toLowerCase()}(url');
    if (params.isNotEmpty) buf.write(', params=params');
    if (headers.isNotEmpty) buf.write(', headers=headers');
    if (req.body.hasContent) buf.write(', data=data');
    buf.writeln(')');
    buf.writeln();
    buf.writeln('print(response.status_code)');
    buf.writeln('print(response.json())');
    return buf.toString();
  }

  static String _toJavaOkHttp(ApiRequest req) {
    final uri = _buildUri(req);
    final buf = StringBuffer();
    buf.writeln('OkHttpClient client = new OkHttpClient();');
    buf.writeln();

    if (req.body.hasContent) {
      buf.writeln(
          'MediaType mediaType = MediaType.parse("${req.body.contentType}");');
      buf.writeln(
          'RequestBody body = RequestBody.create(mediaType, "${req.body.rawContent?.replaceAll('"', '\\"') ?? ''}");');
      buf.writeln();
    }

    buf.writeln('Request request = new Request.Builder()');
    buf.writeln('  .url("${uri.toString()}")');

    for (final h in req.headers.where((h) => h.enabled && h.key.isNotEmpty)) {
      buf.writeln('  .addHeader("${h.key}", "${h.value}")');
    }

    if (req.body.hasContent) {
      buf.writeln('  .${req.method.toLowerCase()}(body)');
    } else if (req.method == 'GET') {
      buf.writeln('  .get()');
    } else {
      buf.writeln('  .${req.method.toLowerCase()}(null)');
    }

    buf.writeln('  .build();');
    buf.writeln();
    buf.writeln('Response response = client.newCall(request).execute();');
    buf.writeln('System.out.println(response.body().string());');
    return buf.toString();
  }

  static Uri _buildUri(ApiRequest req) {
    try {
      final uri = Uri.parse(req.url);
      final params = {
        ...uri.queryParameters,
        for (final p
            in req.queryParams.where((p) => p.enabled && p.key.isNotEmpty))
          p.key: p.value,
      };
      return uri.replace(queryParameters: params.isEmpty ? null : params);
    } catch (_) {
      return Uri.parse(req.url);
    }
  }
}
