/// Guardian Model
/// Represents an emergency contact/guardian
import 'package:cloud_firestore/cloud_firestore.dart';

class Guardian {
  final String id;
  final String userId; // Owner of this guardian
  final String name;
  final String phone;
  final String? email;
  final String? relationship;
  final bool isPrimary; // Primary guardian for auto-call
  final DateTime createdAt;
  final DateTime? updatedAt;

  Guardian({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
    this.isPrimary = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory Guardian.fromMap(Map<String, dynamic> map) {
    return Guardian(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      relationship: map['relationship'],
      isPrimary: map['isPrimary'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Create copy with updated fields
  Guardian copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guardian(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
