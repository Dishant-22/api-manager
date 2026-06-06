import 'package:equatable/equatable.dart';

class KeyValuePair extends Equatable {
  final String id;
  final String key;
  final String value;
  final String? description;
  final bool enabled;

  const KeyValuePair({
    required this.key,
    required this.value,
    String? id,
    this.description,
    this.enabled = true,
  }) : id = id ?? key;

  KeyValuePair copyWith({
    String? id,
    String? key,
    String? value,
    String? description,
    bool? enabled,
  }) =>
      KeyValuePair(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
        'description': description,
        'enabled': enabled,
      };

  factory KeyValuePair.fromJson(Map<String, dynamic> json) => KeyValuePair(
        id: json['id'] as String? ?? json['key'] as String,
        key: json['key'] as String,
        value: json['value'] as String? ?? '',
        description: json['description'] as String?,
        enabled: json['enabled'] as bool? ?? true,
      );

  factory KeyValuePair.empty() => KeyValuePair(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        key: '',
        value: '',
      );

  @override
  List<Object?> get props => [id, key, value, description, enabled];
}
