/// Location Share Service
/// Handles real-time location fetching and sharing
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';

class LocationShareService {
  // Get current location with high accuracy
  Future<LocationModel?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = '${place.street}, ${place.subLocality}, '
              '${place.locality}, ${place.administrativeArea} ${place.postalCode}';
        }
      } catch (e) {
        // Address fetching failed, continue without it
        address = null;
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // Get location stream for live tracking
  Stream<LocationModel> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).asyncMap((position) async {
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = '${place.street}, ${place.locality}';
        }
      } catch (e) {
        address = null;
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
        timestamp: DateTime.now(),
      );
    });
  }

  // Calculate distance between two coordinates (in kilometers)
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(
          startLat,
          startLng,
          endLat,
          endLng,
        ) /
        1000; // Convert to kilometers
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.subLocality}, '
            '${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Open location in maps app
  String getGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  // Generate shareable location message
  String generateShareMessage(LocationModel location) {
    String message = '🚨 EMERGENCY LOCATION ALERT 🚨\n\n';
    message += 'Latitude: ${location.latitude}\n';
    message += 'Longitude: ${location.longitude}\n';
    if (location.address != null) {
      message += 'Address: ${location.address}\n';
    }
    message += '\nGoogle Maps: ${location.googleMapsLink}\n';
    message += '\nTimestamp: ${location.timestamp.toLocal()}';
    return message;
  }
}
