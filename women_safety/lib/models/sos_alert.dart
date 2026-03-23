class SOSAlert {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? mediaUrl;
  final DateTime timestamp;
  final String status; // ACTIVE, RESOLVED, FALSE_ALARM
  final String? triggerType; // BUTTON, SHAKE, VOICE
  final String? notes;

  SOSAlert({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.mediaUrl,
    required this.timestamp,
    this.status = 'ACTIVE',
    this.triggerType,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'triggerType': triggerType,
      'notes': notes,
    };
  }

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id']?.toString(),
      userId: json['userId'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      mediaUrl: json['mediaUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? 'ACTIVE',
      triggerType: json['triggerType'],
      notes: json['notes'],
    );
  }

  String getMapUrl() {
    return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';
  }

  SOSAlert copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? mediaUrl,
    DateTime? timestamp,
    String? status,
    String? triggerType,
    String? notes,
  }) {
    return SOSAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      triggerType: triggerType ?? this.triggerType,
      notes: notes ?? this.notes,
    );
  }
}
