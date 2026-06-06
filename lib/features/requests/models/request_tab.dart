import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'api_request.dart';
import 'api_response.dart';

enum TabStatus { idle, loading, success, error }

class RequestTab extends Equatable {
  final String id;
  final ApiRequest request;
  final ApiResponse? response;
  final TabStatus status;
  final String? errorMessage;
  final bool hasUnsavedChanges;

  RequestTab({
    String? id,
    ApiRequest? request,
    this.response,
    this.status = TabStatus.idle,
    this.errorMessage,
    this.hasUnsavedChanges = false,
  })  : id = id ?? const Uuid().v4(),
        request = request ?? ApiRequest.empty();

  String get title => request.displayName;

  RequestTab copyWith({
    String? id,
    ApiRequest? request,
    ApiResponse? response,
    TabStatus? status,
    String? errorMessage,
    bool? hasUnsavedChanges,
    bool clearResponse = false,
    bool clearError = false,
  }) =>
      RequestTab(
        id: id ?? this.id,
        request: request ?? this.request,
        response: clearResponse ? null : (response ?? this.response),
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'response': response?.toJson(),
        'status': 'idle',
        'hasUnsavedChanges': hasUnsavedChanges,
      };

  factory RequestTab.fromJson(Map<String, dynamic> json) => RequestTab(
        id: json['id'] as String?,
        request: json['request'] != null
            ? ApiRequest.fromJson(json['request'] as Map<String, dynamic>)
            : null,
        response: json['response'] != null
            ? ApiResponse.fromJson(json['response'] as Map<String, dynamic>)
            : null,
        hasUnsavedChanges: json['hasUnsavedChanges'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [id, request, response, status, errorMessage, hasUnsavedChanges];
}
