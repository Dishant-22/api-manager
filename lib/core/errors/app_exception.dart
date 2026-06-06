class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
  });
}

class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code,
    super.originalError,
  });
}

class CancelException extends AppException {
  const CancelException({
    required super.message,
    super.code,
    super.originalError,
  });
}
