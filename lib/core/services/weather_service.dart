import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';

/// Fetches current weather from Visual Crossing REST API.
/// Uses a standalone Dio instance (no auth token — public API).
class WeatherService {
  // Lazy singleton Dio for Visual Crossing (different base URL, no auth)
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Returns current conditions for the configured location.
  Future<ApiResponse<WeatherModel>> getCurrentWeather() async {
    try {
      final url =
          '${ApiConstants.weatherBase}/${ApiConstants.weatherLocation}';

      final response = await _dio.get(
        url,
        queryParameters: {
          'unitGroup': 'metric',
          'include': 'current',
          'key': ApiConstants.weatherApiKey,
          'contentType': 'json',
        },
      );

      final data = response.data as Map<String, dynamic>;
      return ApiResponse.success(WeatherModel.fromJson(data));
    } on DioException catch (e) {
      // Fall through to generic error
      final msg = e.response?.statusCode == 401
          ? 'Invalid weather API key.'
          : e.type == DioExceptionType.connectionError ||
                  e.type == DioExceptionType.connectionTimeout
              ? AppStrings.noInternet
              : AppStrings.genericError;
      return ApiResponse.failure(msg);
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }
}
