import 'package:equatable/equatable.dart';

enum AuthType { none, bearerToken, basicAuth, apiKey, oauth2 }

class AuthConfig extends Equatable {
  final AuthType type;

  // Bearer Token
  final String? bearerToken;

  // Basic Auth
  final String? username;
  final String? password;

  // API Key
  final String? apiKeyName;
  final String? apiKeyValue;
  final String? apiKeyIn; // 'header' or 'query'

  const AuthConfig({
    required this.type,
    this.bearerToken,
    this.username,
    this.password,
    this.apiKeyName,
    this.apiKeyValue,
    this.apiKeyIn = 'header',
  });

  const AuthConfig.none() : this(type: AuthType.none);

  AuthConfig copyWith({
    AuthType? type,
    String? bearerToken,
    String? username,
    String? password,
    String? apiKeyName,
    String? apiKeyValue,
    String? apiKeyIn,
  }) =>
      AuthConfig(
        type: type ?? this.type,
        bearerToken: bearerToken ?? this.bearerToken,
        username: username ?? this.username,
        password: password ?? this.password,
        apiKeyName: apiKeyName ?? this.apiKeyName,
        apiKeyValue: apiKeyValue ?? this.apiKeyValue,
        apiKeyIn: apiKeyIn ?? this.apiKeyIn,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'bearerToken': bearerToken,
        'username': username,
        'password': password,
        'apiKeyName': apiKeyName,
        'apiKeyValue': apiKeyValue,
        'apiKeyIn': apiKeyIn,
      };

  factory AuthConfig.fromJson(Map<String, dynamic> json) => AuthConfig(
        type: AuthType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AuthType.none,
        ),
        bearerToken: json['bearerToken'] as String?,
        username: json['username'] as String?,
        password: json['password'] as String?,
        apiKeyName: json['apiKeyName'] as String?,
        apiKeyValue: json['apiKeyValue'] as String?,
        apiKeyIn: json['apiKeyIn'] as String? ?? 'header',
      );

  @override
  List<Object?> get props => [
        type,
        bearerToken,
        username,
        password,
        apiKeyName,
        apiKeyValue,
        apiKeyIn,
      ];
}
