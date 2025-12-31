/// Base exception class for all app errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Authentication-related errors
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError});

  factory AuthException.invalidCredentials() =>
      AuthException('Invalid email or password', code: 'AUTH_001');

  factory AuthException.emailNotVerified() =>
      AuthException('Please verify your email address', code: 'AUTH_002');

  factory AuthException.sessionExpired() => AuthException(
    'Your session has expired. Please log in again.',
    code: 'AUTH_003',
  );

  factory AuthException.emailAlreadyInUse() =>
      AuthException('This email is already registered', code: 'AUTH_004');

  factory AuthException.weakPassword() => AuthException(
    'Password is too weak. Use at least 8 characters.',
    code: 'AUTH_005',
  );

  factory AuthException.userNotFound() =>
      AuthException('No user found with this email', code: 'AUTH_006');
}

/// Network-related errors (retryable)
class NetworkException extends AppException {
  final bool isRetryable;

  NetworkException(
    super.message, {
    this.isRetryable = true,
    super.code,
    super.originalError,
  });

  factory NetworkException.noConnection() =>
      NetworkException('No internet connection', code: 'NET_001');

  factory NetworkException.timeout() =>
      NetworkException('Request timed out. Please try again.', code: 'NET_002');

  factory NetworkException.serverError() => NetworkException(
    'Server error. Please try again later.',
    code: 'NET_003',
  );
}

/// Database/Supabase errors
class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.originalError});

  factory DatabaseException.notFound() =>
      DatabaseException('Record not found', code: 'DB_001');

  factory DatabaseException.conflict() =>
      DatabaseException('Data conflict detected', code: 'DB_002');

  factory DatabaseException.constraintViolation() =>
      DatabaseException('Data constraint violation', code: 'DB_003');
}

/// Validation errors (user input)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(super.message, {this.fieldErrors, super.code});

  factory ValidationException.invalidEmail() => ValidationException(
    'Please enter a valid email address',
    code: 'VAL_001',
  );

  factory ValidationException.emptyField(String fieldName) =>
      ValidationException('$fieldName cannot be empty', code: 'VAL_002');
}
