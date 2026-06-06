import 'package:equatable/equatable.dart';

class ApiResponse extends Equatable {
  final int statusCode;
  final String statusMessage;
  final Map<String, String> headers;
  final String body;
  final Duration duration;
  final int sizeBytes;
  final String? contentType;
  final DateTime receivedAt;

  ApiResponse({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.body,
    required this.duration,
    required this.sizeBytes,
    this.contentType,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  String get statusText => '$statusCode $statusMessage';

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'statusMessage': statusMessage,
        'headers': headers,
        'body': body,
        'durationMs': duration.inMilliseconds,
        'sizeBytes': sizeBytes,
        'contentType': contentType,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
        statusCode: json['statusCode'] as int,
        statusMessage: json['statusMessage'] as String,
        headers: Map<String, String>.from(json['headers'] as Map),
        body: json['body'] as String,
        duration: Duration(milliseconds: json['durationMs'] as int),
        sizeBytes: json['sizeBytes'] as int,
        contentType: json['contentType'] as String?,
        receivedAt: DateTime.tryParse(json['receivedAt'] as String),
      );

  @override
  List<Object?> get props =>
      [statusCode, statusMessage, body, duration, sizeBytes];
}
