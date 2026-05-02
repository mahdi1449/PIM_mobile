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
    // Robustly extract ID
    final id = (json['id'] ?? json['_id'] ?? json['sub'] ?? json['userId'] ?? '').toString();
    
    // Robustly extract Club ID
    String clubId = '';
    if (json['clubId'] != null) {
      clubId = json['clubId'].toString();
    } else if (json['club'] != null) {
      if (json['club'] is Map) {
        clubId = (json['club']['id'] ?? json['club']['_id'] ?? '').toString();
      } else {
        clubId = json['club'].toString();
      }
    }

    return User(
      id: id,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      clubId: clubId,
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
