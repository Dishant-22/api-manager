import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum VariableScope { global, workspace, environment }

class EnvVariable extends Equatable {
  final String id;
  final String key;
  final String value;
  final String? initialValue;
  final bool isSecret;
  final bool enabled;

  const EnvVariable({
    required this.id,
    required this.key,
    required this.value,
    this.initialValue,
    this.isSecret = false,
    this.enabled = true,
  });

  EnvVariable copyWith({
    String? id,
    String? key,
    String? value,
    String? initialValue,
    bool? isSecret,
    bool? enabled,
  }) =>
      EnvVariable(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        initialValue: initialValue ?? this.initialValue,
        isSecret: isSecret ?? this.isSecret,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
        'initialValue': initialValue,
        'isSecret': isSecret,
        'enabled': enabled,
      };

  factory EnvVariable.fromJson(Map<String, dynamic> json) => EnvVariable(
        id: json['id'] as String,
        key: json['key'] as String,
        value: json['value'] as String? ?? '',
        initialValue: json['initialValue'] as String?,
        isSecret: json['isSecret'] as bool? ?? false,
        enabled: json['enabled'] as bool? ?? true,
      );

  factory EnvVariable.empty() => EnvVariable(
        id: const Uuid().v4(),
        key: '',
        value: '',
      );

  @override
  List<Object?> get props => [id, key, value, isSecret, enabled];
}

class Environment extends Equatable {
  final String id;
  final String name;
  final List<EnvVariable> variables;
  final bool isGlobal;
  final DateTime createdAt;

  Environment({
    String? id,
    required this.name,
    this.variables = const [],
    this.isGlobal = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, String> get resolvedVariables => {
        for (final v in variables.where((v) => v.enabled && v.key.isNotEmpty))
          v.key: v.value,
      };

  Environment copyWith({
    String? id,
    String? name,
    List<EnvVariable>? variables,
    bool? isGlobal,
    DateTime? createdAt,
  }) =>
      Environment(
        id: id ?? this.id,
        name: name ?? this.name,
        variables: variables ?? this.variables,
        isGlobal: isGlobal ?? this.isGlobal,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variables': variables.map((v) => v.toJson()).toList(),
        'isGlobal': isGlobal,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Environment.fromJson(Map<String, dynamic> json) => Environment(
        id: json['id'] as String?,
        name: json['name'] as String,
        variables: (json['variables'] as List<dynamic>?)
                ?.map((e) => EnvVariable.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        isGlobal: json['isGlobal'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [id, name, variables, isGlobal];
}
