/// SOS Log Model
/// Records each SOS event with location and alert details
import 'package:cloud_firestore/cloud_firestore.dart';

class SosLog {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final String status; // 'triggered', 'cancelled', 'resolved'
  final List<String> alertsSent; // ['whatsapp', 'sms', 'email', 'call']
  final String? audioRecordingUrl;
  final String? imageUrl;
  final String? notes;

  SosLog({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    required this.status,
    required this.alertsSent,
    this.audioRecordingUrl,
    this.imageUrl,
    this.notes,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'alertsSent': alertsSent,
      'audioRecordingUrl': audioRecordingUrl,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  // Create from Firestore document
  factory SosLog.fromMap(Map<String, dynamic> map) {
    return SosLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? 'triggered',
      alertsSent: List<String>.from(map['alertsSent'] ?? []),
      audioRecordingUrl: map['audioRecordingUrl'],
      imageUrl: map['imageUrl'],
      notes: map['notes'],
    );
  }

  // Create copy with updated fields
  SosLog copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
    String? status,
    List<String>? alertsSent,
    String? audioRecordingUrl,
    String? imageUrl,
    String? notes,
  }) {
    return SosLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      alertsSent: alertsSent ?? this.alertsSent,
      audioRecordingUrl: audioRecordingUrl ?? this.audioRecordingUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }
}
