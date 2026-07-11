class DriverProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String status;
  final String role;
  final String? avatarPath;

  DriverProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.role,
    this.avatarPath,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  DriverProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarPath,
  }) {
    return DriverProfile(
      userId: userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status,
      role: role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}