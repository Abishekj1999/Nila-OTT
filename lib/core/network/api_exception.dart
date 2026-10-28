import 'package:dio/dio.dart';

enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  premiumRequired,
  notFound,
  validation,
  rateLimited,
  server,
  malformed,
  unknown,
}

/// A user-safe API failure. Raw server exceptions never reach the UI:
/// only validation messages (written for end users by the backend) are kept.
class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.fieldErrors = const {}, this.validationMessage});

  final ApiErrorKind kind;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;
  final String? validationMessage;

  bool get isRetryable => switch (kind) {
        ApiErrorKind.network ||
        ApiErrorKind.timeout ||
        ApiErrorKind.server ||
        ApiErrorKind.rateLimited ||
        ApiErrorKind.malformed ||
        ApiErrorKind.unknown =>
          true,
        _ => false,
      };

  String? firstFieldError(String field) {
    final errors = fieldErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.first;
  }

  String get userMessage => switch (kind) {
        ApiErrorKind.network => 'No connection. Check your internet and try again.',
        ApiErrorKind.timeout => 'The server is taking too long to respond. Please try again.',
        ApiErrorKind.unauthorized => 'Your session has ended. Please sign in again.',
        ApiErrorKind.forbidden => 'You don\'t have access to this content.',
        ApiErrorKind.premiumRequired => 'A premium plan is needed to watch this.',
        ApiErrorKind.notFound => 'This content is not available.',
        ApiErrorKind.validation => validationMessage ?? 'Please check the details and try again.',
        ApiErrorKind.rateLimited => 'Too many attempts. Please wait a minute and try again.',
        ApiErrorKind.server => 'Something went wrong on our side. Please try again.',
        ApiErrorKind.malformed => 'We received an unexpected response. Please try again.',
        ApiErrorKind.unknown => 'Something went wrong. Please try again.',
      };

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return ApiException._fromDio(error);
    if (error is TypeError || error is FormatException) {
      return const ApiException(ApiErrorKind.malformed);
    }
    return const ApiException(ApiErrorKind.unknown);
  }

  static ApiException _fromDio(DioException e) {
    if (e.error is ApiException) return e.error! as ApiException;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(ApiErrorKind.timeout);
      case DioExceptionType.connectionError:
        return const ApiException(ApiErrorKind.network);
      case DioExceptionType.badResponse:
        return _fromResponse(e.response);
      default:
        return const ApiException(ApiErrorKind.unknown);
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final body = response?.data is Map ? response!.data as Map : const {};
    switch (status) {
      case 401:
        return const ApiException(ApiErrorKind.unauthorized, statusCode: 401);
      case 403:
        final premium = body['reason'] == 'premium_required' || body['message'] == 'premium_required';
        return ApiException(
          premium ? ApiErrorKind.premiumRequired : ApiErrorKind.forbidden,
          statusCode: 403,
        );
      case 404:
        return const ApiException(ApiErrorKind.notFound, statusCode: 404);
      case 422:
        final fieldErrors = <String, List<String>>{};
        final errors = body['errors'];
        if (errors is Map) {
          errors.forEach((key, value) {
            if (value is List) fieldErrors['$key'] = value.map((v) => '$v').toList();
          });
        }
        final message = body['message'];
        return ApiException(
          ApiErrorKind.validation,
          statusCode: 422,
          fieldErrors: fieldErrors,
          validationMessage: message is String && message.isNotEmpty ? message : null,
        );
      case 429:
        return const ApiException(ApiErrorKind.rateLimited, statusCode: 429);
      default:
        if (status != null && status >= 500) {
          return ApiException(ApiErrorKind.server, statusCode: status);
        }
        return ApiException(ApiErrorKind.unknown, statusCode: status);
    }
  }

  @override
  String toString() => 'ApiException($kind, status: $statusCode)';
}
