import 'package:bloc_signals/bloc_signals.dart';

import '../../core/services/location_service.dart';

export '../../core/services/location_service.dart' show LocationData;

class LocationState {
  final LocationData? location;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.location,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    LocationData? location,
    bool clearLocation = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LocationState(
      location: clearLocation ? null : (location ?? this.location),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LocationBloc extends CubitSignal<LocationState> {
  final LocationService service;

  LocationBloc(this.service) : super(initialState: const LocationState());

  Future<void> loadSaved() async {
    emit(stateValue.copyWith(isLoading: true, clearError: true));
    try {
      final loc = await service.loadLocation();
      if (loc != null) {
        emit(stateValue.copyWith(location: loc, isLoading: false));
      } else {
        emit(stateValue.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(stateValue.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> requestGps() async {
    emit(stateValue.copyWith(isLoading: true, clearError: true));
    try {
      final loc = await service.getCurrentLocation();
      if (loc != null) {
        await service.saveLocation(loc);
        emit(stateValue.copyWith(location: loc, isLoading: false));
      } else {
        emit(stateValue.copyWith(
          isLoading: false,
          error: 'Could not get GPS location. Check permissions.',
        ));
      }
    } catch (e) {
      emit(stateValue.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> setManual(LocationData location) async {
    await service.saveLocation(location);
    emit(stateValue.copyWith(location: location));
  }

  void clear() {
    emit(stateValue.copyWith(clearLocation: true));
  }
}
