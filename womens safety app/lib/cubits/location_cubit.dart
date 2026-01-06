/// Location Cubit
/// Manages location tracking and sharing state
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/location_model.dart';
import '../services/location_share_service.dart';

// Location States
abstract class LocationState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final LocationModel location;

  LocationLoaded(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationTracking extends LocationState {
  final LocationModel currentLocation;

  LocationTracking(this.currentLocation);

  @override
  List<Object?> get props => [currentLocation];
}

class LocationError extends LocationState {
  final String message;

  LocationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Location Cubit
class LocationCubit extends Cubit<LocationState> {
  final LocationShareService _locationService = LocationShareService();

  LocationCubit() : super(LocationInitial());

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      emit(LocationLoading());

      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        emit(LocationLoaded(location));
      } else {
        emit(LocationError('Failed to get location'));
      }
    } catch (e) {
      emit(LocationError('Location error: $e'));
    }
  }

  // Start live location tracking
  void startLocationTracking() {
    try {
      _locationService.getLocationStream().listen(
        (location) {
          emit(LocationTracking(location));
        },
        onError: (error) {
          emit(LocationError('Tracking error: $error'));
        },
      );
    } catch (e) {
      emit(LocationError('Failed to start tracking: $e'));
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    emit(LocationInitial());
  }

  // Get last known location
  LocationModel? getLastLocation() {
    if (state is LocationLoaded) {
      return (state as LocationLoaded).location;
    } else if (state is LocationTracking) {
      return (state as LocationTracking).currentLocation;
    }
    return null;
  }

  // Calculate distance between two points
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return _locationService.calculateDistance(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }

  // Get address from coordinates
  Future<String?> getAddress(double latitude, double longitude) async {
    try {
      return await _locationService.getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      return null;
    }
  }
}
