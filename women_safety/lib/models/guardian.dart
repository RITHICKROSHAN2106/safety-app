class Guardian {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String relationship;
  final bool isPrimary;
  final String ownerId;

  Guardian({
    this.id = '',
    required this.name,
    required this.phone,
    this.email,
    this.relationship = 'Friend',
    this.isPrimary = false,
    this.ownerId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'ownerId': ownerId,
    };
  }

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      relationship: json['relationship'] ?? 'Friend',
      isPrimary: json['isPrimary'] ?? false,
      ownerId: json['ownerId'] ?? '',
    );
  }

  Guardian copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    bool? isPrimary,
    String? ownerId,
  }) {
    return Guardian(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
