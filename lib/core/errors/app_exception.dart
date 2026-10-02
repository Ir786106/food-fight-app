import 'package:dio/dio.dart';
import 'package:food_fight/core/constants/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Base exception class for the application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return message;
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
    };
  }
}

/// Exception for authentication errors
class AuthenticationException extends AppException {
  AuthenticationException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'auth_error',
        );

  factory AuthenticationException.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AuthenticationException(
          message: AppStrings.networkError,
          code: 'timeout',
        );
      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return AuthenticationException(
            message: AppStrings.authError,
            code: 'unauthorized',
          );
        }
        return AuthenticationException(
          message: AppStrings.serverError,
          code: 'server_error',
        );
      case DioExceptionType.cancel:
        return AuthenticationException(
          message: 'Request cancelled',
          code: 'cancelled',
        );
      case DioExceptionType.connectionError:
        return AuthenticationException(
          message: AppStrings.networkError,
          code: 'network_error',
        );
      default:
        return AuthenticationException(
          message: AppStrings.networkError,
          code: 'unknown',
        );
    }
  }

  factory AuthenticationException.fromFirebase(dynamic error) {
    String message = AppStrings.authError;

    if (error is String) {
      message = error;
    } else if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          message = AppStrings.invalidEmail;
        case 'wrong-password':
          message = AppStrings.authError;
        case 'user-not-found':
          message = 'User not found';
        case 'user-disabled':
          message = 'This user has been disabled';
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
        case 'operation-not-allowed':
          message = 'Operation not allowed';
        case 'email-already-in-use':
          message = 'Email already in use';
        default:
          message = AppStrings.authError;
      }
    }

    return AuthenticationException(
      message: message,
      code: 'auth_error',
    );
  }
}

/// Exception for network errors
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'network_error',
        );

  factory NetworkException.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Connection timeout. Please try again.',
          code: 'timeout',
        );
      case DioExceptionType.badResponse:
        return NetworkException(
          message: AppStrings.serverError,
          code: 'server_error',
        );
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled',
          code: 'cancelled',
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: AppStrings.networkError,
          code: 'network_error',
        );
      default:
        return NetworkException(
          message: AppStrings.networkError,
          code: 'unknown',
        );
    }
  }
}

/// Exception for permission errors
class PermissionException extends AppException {
  PermissionException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'permission_error',
        );
}

/// Exception for validation errors
class ValidationException extends AppException {
  final List<String> fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors = const [],
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'validation_error',
        );
}

/// Exception for storage errors
class StorageException extends AppException {
  StorageException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'storage_error',
        );

  factory StorageException.fromSupabase(dynamic error) {
    if (error is String) {
      return StorageException(message: error, code: 'supabase_error');
    }
    try {
      final dyn = error as dynamic;
      final msg = dyn.message?.toString();
      final status = dyn.statusCode?.toString();
      if (msg != null && msg.isNotEmpty) {
        return StorageException(
          message: status != null ? '[$status] $msg' : msg,
          code: 'supabase_error',
          originalException: error,
        );
      }
    } catch (_) {}
    return StorageException(
      message: error?.toString() ?? AppStrings.imageUploadFailed,
      code: 'storage_error',
      originalException: error,
    );
  }
}

/// Exception for data not found
class DataNotFoundException extends AppException {
  DataNotFoundException({
    required super.message,
    String? code,
    super.originalException,
  }) : super(
          code: code ?? 'not_found',
        );
}
