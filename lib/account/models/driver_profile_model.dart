class DriverProfile {
  final String name;
  final String email;
  final String phone;
  final String? avatarPath;

  DriverProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.avatarPath,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatarPath: json['avatarPath'] as String?,
    );
  }

  DriverProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarPath,
  }) {
    return DriverProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}