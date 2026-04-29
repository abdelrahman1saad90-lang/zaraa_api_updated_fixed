import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/app_strings.dart';

/// Converts Dio exceptions and ASP.NET validation payloads into
/// user-facing messages that reflect the real failure cause.
class ApiErrorHandler {
  ApiErrorHandler._();

  static String message(
    DioException exception, {
    String? fallbackMessage,
    bool authRequest = false,
    String? unauthorizedMessage,
    String? notFoundMessage,
    String? conflictMessage,
  }) {
    final statusCode = exception.response?.statusCode;
    final serverMessage = _extractMessage(exception.response?.data);

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection to the server failed.';
      case DioExceptionType.connectionError:
        return _connectionMessage(exception);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    switch (statusCode) {
      case 400:
      case 422:
        return serverMessage ?? fallbackMessage ?? AppStrings.genericError;
      case 401:
        return serverMessage ?? unauthorizedMessage ?? (authRequest ? AppStrings.invalidCredentials : 'Unauthorized request.');
      case 403:
        return serverMessage ?? 'You are not allowed to perform this action.';
      case 404:
        return serverMessage ?? notFoundMessage ?? 'Requested resource was not found.';
      case 409:
        return serverMessage ?? conflictMessage ?? 'This email or username is already registered.';
      case 423:
        return serverMessage ?? AppStrings.accountSuspended;
      case 429:
        return serverMessage ?? AppStrings.tooManyAttempts;
      case 500:
      case 502:
      case 503:
        return 'Server is temporarily unavailable. Please try again later.';
      default:
        return serverMessage ?? fallbackMessage ?? AppStrings.genericError;
    }
  }

  static String _connectionMessage(DioException exception) {
    final raw = '${exception.error ?? exception.message ?? ''}'.toLowerCase();

    if (raw.contains('failed host lookup') || raw.contains('socketexception') || raw.contains('network is unreachable')) {
      return AppStrings.noInternet;
    }

    if (raw.contains('handshakeexception') || raw.contains('certificate') || raw.contains('cert')) {
      return 'Secure connection to the server failed.';
    }

    if (raw.contains('connection refused') || raw.contains('connection closed')) {
      return 'Could not reach the server. Please try again.';
    }

    return 'Unable to reach the server. Please try again.';
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;

      try {
        final decoded = jsonDecode(trimmed);
        return _extractMessage(decoded) ?? trimmed;
      } catch (_) {
        return trimmed;
      }
    }

    if (data is List) {
      return _joinMessages(data.map(_extractMessage).whereType<String>());
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );

      for (final key in const ['message', 'detail', 'error']) {
        final directMessage = _extractMessage(map[key]);
        if (directMessage != null && directMessage.isNotEmpty) {
          return directMessage;
        }
      }

      final validationMessage = _extractMessage(map['errors']);
      if (validationMessage != null && validationMessage.isNotEmpty) {
        return validationMessage;
      }

      final titleMessage = _extractMessage(map['title']);
      if (titleMessage != null && titleMessage.isNotEmpty) {
        return titleMessage;
      }

      const ignoredKeys = {'type', 'status', 'traceId', 'instance'};
      final messages = <String>[];

      for (final entry in map.entries) {
        if (ignoredKeys.contains(entry.key)) continue;
        final valueMessage = _extractMessage(entry.value);
        if (valueMessage != null && valueMessage.isNotEmpty) {
          messages.add(valueMessage);
        }
      }

      return _joinMessages(messages);
    }

    final value = data.toString().trim();
    return value.isEmpty ? null : value;
  }

  static String? _joinMessages(Iterable<String> messages) {
    final uniqueMessages = <String>[];

    for (final message in messages) {
      final trimmed = message.trim();
      if (trimmed.isEmpty || uniqueMessages.contains(trimmed)) continue;
      uniqueMessages.add(trimmed);
    }

    if (uniqueMessages.isEmpty) return null;
    return uniqueMessages.join('\n');
  }
}
