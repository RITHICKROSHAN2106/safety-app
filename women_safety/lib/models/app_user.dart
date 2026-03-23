class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final List<String>? emergencyContactIds;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.emergencyContactIds,
  });

  // Convenience getters
  String get id => uid;
  String get name => displayName ?? email?.split('@').first ?? 'User';

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'emergencyContactIds': emergencyContactIds,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      displayName: json['displayName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      emergencyContactIds: json['emergencyContactIds'] != null
          ? List<String>.from(json['emergencyContactIds'])
          : null,
    );
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    List<String>? emergencyContactIds,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContactIds: emergencyContactIds ?? this.emergencyContactIds,
    );
  }
}
