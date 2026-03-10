import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Error types for classification
enum ErrorType {
  network,
  timeout,
  server,
  authentication,
  authorization,
  validation,
  notFound,
  unknown,
}

/// Error handler utility class
class ErrorHandler {
  /// Extract user-friendly error message from DioException
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _extractDioErrorMessage(error);
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  /// Extract error message from DioException
  static String _extractDioErrorMessage(DioException error) {
    // Try to extract message from response
    if (error.response != null) {
      final responseData = error.response!.data;
      if (responseData is Map) {
        final message = responseData['message']?.toString() ??
            responseData['error']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }

    // Map error types to user-friendly messages
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';

      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network settings.';

      case DioExceptionType.badResponse:
        return _getHttpErrorMessage(error.response?.statusCode);

      case DioExceptionType.cancel:
        return 'Request cancelled.';

      case DioExceptionType.unknown:
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get user-friendly message for HTTP status codes
  static String _getHttpErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication failed. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. This resource already exists.';
      case 413:
        return 'File size too large. Please compress the image and try again.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Classify error type
  static ErrorType classifyError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ErrorType.timeout;

        case DioExceptionType.connectionError:
          return ErrorType.network;

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return ErrorType.authentication;
          } else if (statusCode == 403) {
            return ErrorType.authorization;
          } else if (statusCode == 400 || statusCode == 422) {
            return ErrorType.validation;
          } else if (statusCode == 404) {
            return ErrorType.notFound;
          } else if (statusCode == 413) {
            return ErrorType.validation; // File size validation error
          } else if (statusCode != null && statusCode >= 500) {
            return ErrorType.server;
          }
          return ErrorType.unknown;

        default:
          return ErrorType.unknown;
      }
    }
    return ErrorType.unknown;
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    final errorType = classifyError(error);
    return errorType == ErrorType.network ||
        errorType == ErrorType.timeout ||
        errorType == ErrorType.server;
  }

  /// Get retry suggestion message
  static String getRetrySuggestion(dynamic error) {
    final errorType = classifyError(error);
    switch (errorType) {
      case ErrorType.network:
        return 'Check your internet connection and try again.';
      case ErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ErrorType.server:
        return 'Server error occurred. Please try again in a moment.';
      default:
        return 'Please try again.';
    }
  }

  /// Log error for debugging
  static void logError(dynamic error, {String? context}) {
    if (kDebugMode) {
      print('ErrorHandler: ${context ?? 'Error'}');
      print('ErrorHandler: Type: ${classifyError(error)}');
      print('ErrorHandler: Message: ${getErrorMessage(error)}');
      if (error is DioException) {
        print('ErrorHandler: Status Code: ${error.response?.statusCode}');
        print('ErrorHandler: Request Path: ${error.requestOptions.path}');
        if (error.response?.data != null) {
          print('ErrorHandler: Response Data: ${error.response?.data}');
        }
      }
    }
  }
}
