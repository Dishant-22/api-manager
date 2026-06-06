import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../requests/models/api_request.dart';

class SavedRequest extends Equatable {
  final String id;
  final String name;
  final ApiRequest request;
  final DateTime savedAt;

  SavedRequest({
    String? id,
    required this.name,
    required this.request,
    DateTime? savedAt,
  })  : id = id ?? const Uuid().v4(),
        savedAt = savedAt ?? DateTime.now();

  SavedRequest copyWith({
    String? id,
    String? name,
    ApiRequest? request,
    DateTime? savedAt,
  }) =>
      SavedRequest(
        id: id ?? this.id,
        name: name ?? this.name,
        request: request ?? this.request,
        savedAt: savedAt ?? this.savedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'request': request.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedRequest.fromJson(Map<String, dynamic> json) => SavedRequest(
        id: json['id'] as String?,
        name: json['name'] as String,
        request: ApiRequest.fromJson(json['request'] as Map<String, dynamic>),
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [id, name, request, savedAt];
}

class CollectionFolder extends Equatable {
  final String id;
  final String name;
  final List<SavedRequest> requests;
  final List<CollectionFolder> subFolders;

  CollectionFolder({
    String? id,
    required this.name,
    this.requests = const [],
    this.subFolders = const [],
  }) : id = id ?? const Uuid().v4();

  int get totalRequests =>
      requests.length +
      subFolders.fold(0, (sum, f) => sum + f.totalRequests);

  CollectionFolder copyWith({
    String? id,
    String? name,
    List<SavedRequest>? requests,
    List<CollectionFolder>? subFolders,
  }) =>
      CollectionFolder(
        id: id ?? this.id,
        name: name ?? this.name,
        requests: requests ?? this.requests,
        subFolders: subFolders ?? this.subFolders,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'requests': requests.map((r) => r.toJson()).toList(),
        'subFolders': subFolders.map((f) => f.toJson()).toList(),
      };

  factory CollectionFolder.fromJson(Map<String, dynamic> json) =>
      CollectionFolder(
        id: json['id'] as String?,
        name: json['name'] as String,
        requests: (json['requests'] as List<dynamic>?)
                ?.map((e) => SavedRequest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subFolders: (json['subFolders'] as List<dynamic>?)
                ?.map(
                    (e) => CollectionFolder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [id, name, requests, subFolders];
}

class Collection extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<SavedRequest> requests;
  final List<CollectionFolder> folders;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection({
    String? id,
    required this.name,
    this.description,
    this.requests = const [],
    this.folders = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get totalRequests =>
      requests.length + folders.fold(0, (sum, f) => sum + f.totalRequests);

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    List<SavedRequest>? requests,
    List<CollectionFolder>? folders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        requests: requests ?? this.requests,
        folders: folders ?? this.folders,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requests': requests.map((r) => r.toJson()).toList(),
        'folders': folders.map((f) => f.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
        id: json['id'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        requests: (json['requests'] as List<dynamic>?)
                ?.map((e) => SavedRequest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        folders: (json['folders'] as List<dynamic>?)
                ?.map((e) =>
                    CollectionFolder.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props =>
      [id, name, description, requests, folders, createdAt, updatedAt];
}
