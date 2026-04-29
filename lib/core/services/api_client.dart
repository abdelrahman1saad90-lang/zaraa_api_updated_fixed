import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';

/// Singleton Dio client used by the full app.
/// - Adds bearer tokens to protected requests.
/// - Retries protected requests once after a silent refresh.
class ApiClient {
  ApiClient._();

  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _retryKey = 'retried_after_refresh';

  late final Dio _dio;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          Headers.contentTypeHeader: Headers.jsonContentType,
          Headers.acceptHeader: 'application/json, text/plain, */*',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(_tokenKey);

          print("REQUEST → ${options.path}");
          print("TOKEN → $token");

          if (token != null && token.isNotEmpty && !_isAnonymousRequest(options.path)) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          final shouldRetry = error.response?.statusCode == 401 && !_isAnonymousRequest(requestOptions.path) && requestOptions.extra[_retryKey] != true;

          if (!shouldRetry) {
            handler.next(error);
            return;
          }

          final refreshed = await _tryRefreshToken();
          if (!refreshed) {
            handler.next(error);
            return;
          }

          try {
            final prefs = await SharedPreferences.getInstance();
            final newToken = prefs.getString(_tokenKey);

            requestOptions.extra[_retryKey] = true;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';

            final response = await _dio.fetch(requestOptions);
            handler.resolve(response);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

    _initialized = true;
  }

  Dio get dio {
    assert(_initialized, 'ApiClient.init() must be called before use');
    return _dio;
  }

  bool _isAnonymousRequest(String path) {
    // Normalise both sides so case differences don't cause a miss.
    final normalizedPath = path.toLowerCase();
    final anonymousPaths = {
      ApiConstants.login.toLowerCase(),
      ApiConstants.register.toLowerCase(),
      ApiConstants.confirmEmail.toLowerCase(),
      ApiConstants.resendConfirmation.toLowerCase(),
      ApiConstants.forgotPassword.toLowerCase(),
      ApiConstants.resetPassword.toLowerCase(),
      ApiConstants.changePassword.toLowerCase(),
      ApiConstants.refreshToken.toLowerCase(),
    };

    return anonymousPaths.contains(normalizedPath);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            Headers.contentTypeHeader: Headers.jsonContentType,
            Headers.acceptHeader: 'application/json, text/plain, */*',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
      );

      final newAccess = response.data['accessToken'] as String?;
      final newRefresh = response.data['refreshToken'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        return false;
      }

      await prefs.setString(_tokenKey, newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await prefs.setString(_refreshTokenKey, newRefresh);
      } else {
        await prefs.remove(_refreshTokenKey);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);

    if (refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}

/// Generic wrapper for API responses.
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResponse.success(this.data)
      : error = null,
        isSuccess = true;

  const ApiResponse.failure(this.error)
      : data = null,
        isSuccess = false;
}
