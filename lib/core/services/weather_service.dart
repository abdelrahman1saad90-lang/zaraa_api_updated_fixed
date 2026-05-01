import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';

/// Fetches current weather from Visual Crossing REST API.
/// Uses a standalone Dio instance (no auth token — public API).
class WeatherService {
  // Lazy singleton Dio for Visual Crossing/Open-Meteo
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Returns current conditions for the configured location.
  Future<ApiResponse<WeatherModel>> getCurrentWeather() async {
    try {
      print('>>> WeatherService: Attempting to fetch weather data...');
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': 30.0626, // Cairo Latitude
          'longitude': 31.2497, // Cairo Longitude
          'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
          'timezone': 'auto',
        },
      );
      print('>>> WeatherService: Success! Data received: \${response.data}');

      final data = response.data as Map<String, dynamic>;
      return ApiResponse.success(WeatherModel.fromJson(data));
    } on DioException catch (e) {
      print('>>> WeatherService DioException: \$e');
      final msg = e.type == DioExceptionType.connectionError ||
                  e.type == DioExceptionType.connectionTimeout
              ? AppStrings.noInternet
              : AppStrings.genericError;
      return ApiResponse.failure(msg);
    } catch (e) {
      print('>>> WeatherService Unknown Error: \$e');
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }
}
