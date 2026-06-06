import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import '../../core/errors/app_exception.dart';
import '../../features/requests/models/api_request.dart';
import '../../features/requests/models/api_response.dart';
import '../../features/requests/models/auth_config.dart';
import '../../features/requests/models/request_body.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio _buildDio({
    required int timeoutSeconds,
    required bool followRedirects,
    bool verifySsl = true,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: timeoutSeconds),
        receiveTimeout: Duration(seconds: timeoutSeconds),
        sendTimeout: Duration(seconds: timeoutSeconds),
        followRedirects: followRedirects,
        validateStatus: (_) => true, // Accept all status codes
        responseType: ResponseType.plain,
      ),
    );

    dio.interceptors.add(LoggingInterceptor());

    return dio;
  }

  static Future<ApiResponse> execute({
    required ApiRequest request,
    required Map<String, String> resolvedVariables,
    int timeoutSeconds = 30,
    bool followRedirects = true,
    bool verifySsl = true,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dio = _buildDio(
        timeoutSeconds: timeoutSeconds,
        followRedirects: followRedirects,
        verifySsl: verifySsl,
      );

      // Resolve variables in URL
      final rawUrl = request.url.resolveVars(resolvedVariables);
      final uri = Uri.parse(rawUrl);

      // Build query parameters (merge URL params + explicit params)
      final queryParams = <String, dynamic>{
        ...uri.queryParameters,
        for (final p in request.queryParams.where((p) => p.enabled && p.key.isNotEmpty))
          p.key.resolveVars(resolvedVariables):
              p.value.resolveVars(resolvedVariables),
      };

      // Build headers
      final headers = <String, String>{};
      for (final h in request.headers.where((h) => h.enabled && h.key.isNotEmpty)) {
        headers[h.key.resolveVars(resolvedVariables)] =
            h.value.resolveVars(resolvedVariables);
      }

      // Apply authentication
      _applyAuth(headers, request.auth, resolvedVariables);

      // Build clean URL without existing query params
      final cleanUrl = uri.replace(queryParameters: {}).toString().replaceAll('?', '');

      // Build request data
      final dynamic data = await _buildRequestData(
        request.body,
        resolvedVariables,
        headers,
      );

      final response = await dio.request<String>(
        cleanUrl,
        queryParameters: queryParams.isEmpty ? null : queryParams,
        data: data,
        options: Options(
          method: request.method,
          headers: headers,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      stopwatch.stop();

      final body = response.data ?? '';
      final responseHeaders = <String, String>{};
      response.headers.forEach(
          (name, values) => responseHeaders[name] = values.join(', '));

      final contentType = responseHeaders['content-type'] ??
          responseHeaders['Content-Type'];

      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        headers: responseHeaders,
        body: body,
        duration: stopwatch.elapsed,
        sizeBytes: utf8.encode(body).length,
        contentType: contentType,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw TimeoutException(
            message: 'Request timed out after ${timeoutSeconds}s',
            originalError: e,
          );
        case DioExceptionType.cancel:
          throw CancelException(
            message: 'Request was cancelled',
            originalError: e,
          );
        case DioExceptionType.connectionError:
          throw NetworkException(
            message: e.message ?? 'Connection failed',
            originalError: e,
          );
        default:
          if (e.response != null) {
            final body = e.response?.data?.toString() ?? '';
            final responseHeaders = <String, String>{};
            e.response?.headers.forEach(
                (name, values) => responseHeaders[name] = values.join(', '));
            return ApiResponse(
              statusCode: e.response!.statusCode ?? 0,
              statusMessage: e.response!.statusMessage ?? '',
              headers: responseHeaders,
              body: body,
              duration: stopwatch.elapsed,
              sizeBytes: utf8.encode(body).length,
            );
          }
          throw NetworkException(
            message: e.message ?? 'Network error',
            originalError: e,
          );
      }
    } catch (e) {
      stopwatch.stop();
      throw NetworkException(
        message: e.toString(),
        originalError: e,
      );
    }
  }

  static void _applyAuth(
    Map<String, String> headers,
    AuthConfig auth,
    Map<String, String> vars,
  ) {
    switch (auth.type) {
      case AuthType.bearerToken:
        final token = auth.bearerToken?.resolveVars(vars) ?? '';
        if (token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      case AuthType.basicAuth:
        final user = auth.username?.resolveVars(vars) ?? '';
        final pass = auth.password?.resolveVars(vars) ?? '';
        if (user.isNotEmpty) {
          final encoded = base64Encode(utf8.encode('$user:$pass'));
          headers['Authorization'] = 'Basic $encoded';
        }
      case AuthType.apiKey:
        final name = auth.apiKeyName?.resolveVars(vars) ?? '';
        final value = auth.apiKeyValue?.resolveVars(vars) ?? '';
        if (name.isNotEmpty && value.isNotEmpty && auth.apiKeyIn == 'header') {
          headers[name] = value;
        }
      default:
        break;
    }
  }

  static Future<dynamic> _buildRequestData(
    RequestBody body,
    Map<String, String> vars,
    Map<String, String> headers,
  ) async {
    switch (body.type) {
      case BodyType.none:
        return null;
      case BodyType.rawJson:
        headers['Content-Type'] = 'application/json';
        return body.rawContent?.resolveVars(vars);
      case BodyType.rawText:
        headers['Content-Type'] = 'text/plain';
        return body.rawContent?.resolveVars(vars);
      case BodyType.rawXml:
        headers['Content-Type'] = 'application/xml';
        return body.rawContent?.resolveVars(vars);
      case BodyType.formUrlEncoded:
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        return {
          for (final f
              in body.urlEncodedFields.where((f) => f.enabled && f.key.isNotEmpty))
            f.key.resolveVars(vars): f.value.resolveVars(vars),
        };
      case BodyType.formData:
        final formData = FormData();
        for (final f in body.formFields.where((f) => f.enabled && f.key.isNotEmpty)) {
          if (f.isFile && f.filePath != null) {
            final filename = f.filePath!.split('/').last.split('\\').last;
            final mimeType = lookupMimeType(f.filePath!) ?? 'application/octet-stream';
            formData.files.add(MapEntry(
              f.key,
              await MultipartFile.fromFile(
                f.filePath!,
                filename: filename,
                contentType: DioMediaType.parse(mimeType),
              ),
            ));
          } else {
            formData.fields.add(MapEntry(
              f.key.resolveVars(vars),
              f.value.resolveVars(vars),
            ));
          }
        }
        return formData;
    }
  }
}

extension _StringResolve on String {
  String resolveVars(Map<String, String> vars) {
    var result = this;
    for (final entry in vars.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }
}
