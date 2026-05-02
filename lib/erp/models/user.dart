class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String clubId;
  final String role;
  final String? userType;
  final String status;
  final String? playerId;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.clubId,
    required this.role,
    this.userType,
    this.status = 'active',
    this.playerId,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      clubId: json['clubId'] ?? '',
      role: json['role'] ?? '',
      userType: json['userType'],
      status: json['status'] ?? 'active',
      playerId: json['playerId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'clubId': clubId,
    'role': role,
  };
}
