/// Location Model
/// Represents geographic coordinates with timestamp
class LocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
    required this.timestamp,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Map
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      accuracy: map['accuracy']?.toDouble(),
      address: map['address'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // Generate Google Maps link
  String get googleMapsLink {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  // Generate shareable text
  String get shareableText {
    final addressText = address != null ? '\nAddress: $address' : '';
    return 'My current location:$addressText\n$googleMapsLink';
  }

  // Create copy with updated fields
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
