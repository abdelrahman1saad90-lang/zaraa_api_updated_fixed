import 'dart:convert';
import 'package:dio/dio.dart';

class WeatherModel {
  final String location;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String airQuality;
  final String? icon;

  const WeatherModel({
    required this.location,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.airQuality,
    this.icon,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current =
        json['currentConditions'] as Map<String, dynamic>? ?? {};

    final rawAddress = json['resolvedAddress'] as String? ?? 'Unknown';
    final location = rawAddress
        .split(',')
        .take(2)
        .map((part) => part
            .trim()
            .split(' ')
            .map((w) => w.isEmpty
                ? ''
                : '\${w[0].toUpperCase()}\${w.substring(1).toLowerCase()}')
            .join(' '))
        .join(', ');

    final conditions = current['conditions'] as String? ?? 'Good';

    return WeatherModel(
      location: location.isEmpty ? 'Cairo, EG' : location,
      temperature: (current['temp'] ?? 0).toDouble(),
      humidity: (current['humidity'] ?? 0).toDouble().toInt(),
      windSpeed: (current['windspeed'] ?? 0).toDouble(),
      airQuality: conditions,
      icon: current['icon'] as String?,
    );
  }
}

void main() async {
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      },
    ),
  );

  try {
    final response = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': 30.0626,
        'longitude': 31.2497,
        'current_weather': true,
      },
    );
    print('SUCCESS! Response status: \${response.statusCode}');
    print(response.data);
  } on DioException catch (e) {
    print('DioException: $e');
  } catch (e) {
    print('Other exception: $e');
  }
}
