import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/weather_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

class WeatherLoaded extends WeatherState {
  final WeatherModel weather;
  const WeatherLoaded(this.weather);

  @override
  List<Object?> get props => [weather];
}

class WeatherError extends WeatherState {
  final String message;
  final WeatherModel fallback;

  const WeatherError(this.message, {this.fallback = WeatherModel.demo});

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT
// ══════════════════════════════════════════════════════════════

/// Fetches current weather from Visual Crossing API.
/// Falls back to WeatherModel.demo on failure so the UI never breaks.
class WeatherCubit extends Cubit<WeatherState> {
  final WeatherService _service;

  WeatherCubit(this._service) : super(const WeatherInitial());

  Future<void> loadWeather() async {
    emit(const WeatherLoading());

    final res = await _service.getCurrentWeather();

    if (res.isSuccess) {
      emit(WeatherLoaded(res.data!));
    } else {
      // Emit error but keep demo data so dashboard still renders
      emit(WeatherError(
        res.error ?? 'Could not load weather',
        fallback: WeatherModel.demo,
      ));
    }
  }

  /// Refresh — same as loadWeather but can be called from UI.
  Future<void> refresh() => loadWeather();
}
