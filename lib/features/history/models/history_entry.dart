import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../requests/models/api_request.dart';
import '../../requests/models/api_response.dart';

class HistoryEntry extends Equatable {
  final String id;
  final ApiRequest request;
  final ApiResponse? response;
  final bool isError;
  final String? errorMessage;
  final DateTime executedAt;

  HistoryEntry({
    String? id,
    required this.request,
    this.response,
    this.isError = false,
    this.errorMessage,
    DateTime? executedAt,
  })  : id = id ?? const Uuid().v4(),
        executedAt = executedAt ?? DateTime.now();

  HistoryEntry copyWith({
    String? id,
    ApiRequest? request,
    ApiResponse? response,
    bool? isError,
    String? errorMessage,
    DateTime? executedAt,
  }) =>
      HistoryEntry(
        id: id ?? this.id,
        request: request ?? this.request,
        response: response ?? this.response,
        isError: isError ?? this.isError,
        errorMessage: errorMessage ?? this.errorMessage,
        executedAt: executedAt ?? this.executedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'response': response?.toJson(),
        'isError': isError,
        'errorMessage': errorMessage,
        'executedAt': executedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String?,
        request: ApiRequest.fromJson(json['request'] as Map<String, dynamic>),
        response: json['response'] != null
            ? ApiResponse.fromJson(json['response'] as Map<String, dynamic>)
            : null,
        isError: json['isError'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
        executedAt: DateTime.tryParse(json['executedAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [id, request, response, isError, executedAt];
}
