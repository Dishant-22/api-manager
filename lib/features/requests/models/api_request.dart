import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'key_value_pair.dart';
import 'auth_config.dart';
import 'request_body.dart';

class ApiRequest extends Equatable {
  final String id;
  final String name;
  final String method;
  final String url;
  final List<KeyValuePair> queryParams;
  final List<KeyValuePair> headers;
  final AuthConfig auth;
  final RequestBody body;
  final DateTime? createdAt;

  ApiRequest({
    String? id,
    this.name = 'Untitled Request',
    this.method = 'GET',
    this.url = '',
    this.queryParams = const [],
    this.headers = const [],
    AuthConfig? auth,
    RequestBody? body,
    this.createdAt,
  })  : id = id ?? const Uuid().v4(),
        auth = auth ?? const AuthConfig(type: AuthType.none),
        body = body ?? const RequestBody(type: BodyType.none);

  // Regex: optional scheme+host (handles {{variable}} in host too), then captures path
  static final _pathExtractor =
      RegExp(r'^(?:[a-zA-Z][\w+\-.]*://)?(?:[^/?#\s]+)(/[^?#\s]*)?');

  String get displayName {
    if (name.isNotEmpty && name != 'Untitled Request') return name;
    if (url.isEmpty) return 'Untitled Request';

    final match = _pathExtractor.firstMatch(url);
    if (match != null) {
      var path = match.group(1) ?? '';
      if (path.isNotEmpty && path != '/') {
        // Decode %xx sequences and strip leading slash
        try {
          path = Uri.decodeFull(path);
        } catch (_) {}
        path = path.replaceAll(RegExp(r'^/+'), '');
        if (path.isNotEmpty) return path;
      }
      // No meaningful path — fall back to the host portion
      final full = match.group(0) ?? '';
      // Strip scheme to get just the host
      final hostOnly =
          full.replaceAll(RegExp(r'^[a-zA-Z][\w+\-.]*://'), '').trim();
      if (hostOnly.isNotEmpty) return hostOnly;
    }

    return 'Untitled Request';
  }

  ApiRequest copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<KeyValuePair>? queryParams,
    List<KeyValuePair>? headers,
    AuthConfig? auth,
    RequestBody? body,
    DateTime? createdAt,
  }) =>
      ApiRequest(
        id: id ?? this.id,
        name: name ?? this.name,
        method: method ?? this.method,
        url: url ?? this.url,
        queryParams: queryParams ?? this.queryParams,
        headers: headers ?? this.headers,
        auth: auth ?? this.auth,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
        'queryParams': queryParams.map((p) => p.toJson()).toList(),
        'headers': headers.map((h) => h.toJson()).toList(),
        'auth': auth.toJson(),
        'body': body.toJson(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ApiRequest.fromJson(Map<String, dynamic> json) => ApiRequest(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Untitled Request',
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String? ?? '',
        queryParams: (json['queryParams'] as List<dynamic>?)
                ?.map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        headers: (json['headers'] as List<dynamic>?)
                ?.map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        auth: json['auth'] != null
            ? AuthConfig.fromJson(json['auth'] as Map<String, dynamic>)
            : const AuthConfig(type: AuthType.none),
        body: json['body'] != null
            ? RequestBody.fromJson(json['body'] as Map<String, dynamic>)
            : const RequestBody(type: BodyType.none),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  factory ApiRequest.empty() => ApiRequest();

  @override
  List<Object?> get props =>
      [id, name, method, url, queryParams, headers, auth, body];
}
