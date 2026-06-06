import 'package:equatable/equatable.dart';
import 'key_value_pair.dart';

enum BodyType { none, rawJson, rawText, rawXml, formData, formUrlEncoded }

class MultipartField extends Equatable {
  final String id;
  final String key;
  final String value;
  final bool isFile;
  final String? filePath;
  final bool enabled;

  const MultipartField({
    required this.id,
    required this.key,
    required this.value,
    this.isFile = false,
    this.filePath,
    this.enabled = true,
  });

  MultipartField copyWith({
    String? id,
    String? key,
    String? value,
    bool? isFile,
    String? filePath,
    bool? enabled,
  }) =>
      MultipartField(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
        isFile: isFile ?? this.isFile,
        filePath: filePath ?? this.filePath,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
        'isFile': isFile,
        'filePath': filePath,
        'enabled': enabled,
      };

  factory MultipartField.fromJson(Map<String, dynamic> json) => MultipartField(
        id: json['id'] as String,
        key: json['key'] as String,
        value: json['value'] as String? ?? '',
        isFile: json['isFile'] as bool? ?? false,
        filePath: json['filePath'] as String?,
        enabled: json['enabled'] as bool? ?? true,
      );

  factory MultipartField.empty() => MultipartField(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        key: '',
        value: '',
      );

  @override
  List<Object?> get props => [id, key, value, isFile, filePath, enabled];
}

class RequestBody extends Equatable {
  final BodyType type;
  final String? rawContent;
  final List<MultipartField> formFields;
  final List<KeyValuePair> urlEncodedFields;

  const RequestBody({
    required this.type,
    this.rawContent,
    this.formFields = const [],
    this.urlEncodedFields = const [],
  });

  const RequestBody.empty()
      : this(
          type: BodyType.none,
          rawContent: '',
          formFields: const [],
          urlEncodedFields: const [],
        );

  bool get hasContent {
    switch (type) {
      case BodyType.none:
        return false;
      case BodyType.rawJson:
      case BodyType.rawText:
      case BodyType.rawXml:
        return rawContent != null && rawContent!.isNotEmpty;
      case BodyType.formData:
        return formFields.any((f) => f.key.isNotEmpty && f.enabled);
      case BodyType.formUrlEncoded:
        return urlEncodedFields.any((f) => f.key.isNotEmpty && f.enabled);
    }
  }

  String get contentType {
    switch (type) {
      case BodyType.none:
        return '';
      case BodyType.rawJson:
        return 'application/json';
      case BodyType.rawText:
        return 'text/plain';
      case BodyType.rawXml:
        return 'application/xml';
      case BodyType.formData:
        return 'multipart/form-data';
      case BodyType.formUrlEncoded:
        return 'application/x-www-form-urlencoded';
    }
  }

  RequestBody copyWith({
    BodyType? type,
    String? rawContent,
    List<MultipartField>? formFields,
    List<KeyValuePair>? urlEncodedFields,
  }) =>
      RequestBody(
        type: type ?? this.type,
        rawContent: rawContent ?? this.rawContent,
        formFields: formFields ?? this.formFields,
        urlEncodedFields: urlEncodedFields ?? this.urlEncodedFields,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'rawContent': rawContent,
        'formFields': formFields.map((f) => f.toJson()).toList(),
        'urlEncodedFields': urlEncodedFields.map((f) => f.toJson()).toList(),
      };

  factory RequestBody.fromJson(Map<String, dynamic> json) => RequestBody(
        type: BodyType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BodyType.none,
        ),
        rawContent: json['rawContent'] as String?,
        formFields: (json['formFields'] as List<dynamic>?)
                ?.map((e) => MultipartField.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        urlEncodedFields: (json['urlEncodedFields'] as List<dynamic>?)
                ?.map((e) => KeyValuePair.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  @override
  List<Object?> get props => [type, rawContent, formFields, urlEncodedFields];
}
