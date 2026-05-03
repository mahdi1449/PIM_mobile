class ClubModel {
  ClubModel({
    required this.id,
    required this.name,
    required this.league,
    this.country,
    this.city,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String league;
  final String? country;
  final String? city;
  final String status;
  final DateTime? createdAt;

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class UserModel {
  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    this.clubId,
    required this.role,
    required this.status,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? clubId;
  final String role;
  final String status;

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      photoUrl: json['photoUrl']?.toString(),
      clubId: (json['clubId'] ?? json['club']?['_id'])?.toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class AuditLogModel {
  AuditLogModel({
    required this.id,
    required this.action,
    required this.module,
    required this.entityType,
    this.entityId,
    this.userId,
    this.userEmail,
    this.userName,
    this.actorEmail,
    this.actorName,
    this.userRole,
    this.clubId,
    this.clubName,
    this.teamId,
    this.teamName,
    this.ipAddress,
    this.route,
    this.method,
    this.statusCode,
    this.durationMs,
    this.metadata,
    this.suspicious = false,
    this.suspiciousReason,
    this.createdAt,
  });

  final String id;
  final String action;
  final String module;
  final String entityType;
  final String? entityId;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final String? actorEmail;
  final String? actorName;
  final String? userRole;
  final String? clubId;
  final String? clubName;
  final String? teamId;
  final String? teamName;
  final String? ipAddress;
  final String? route;
  final String? method;
  final int? statusCode;
  final int? durationMs;
  final Map<String, dynamic>? metadata;
  final bool suspicious;
  final String? suspiciousReason;
  final DateTime? createdAt;

  String get displayUser {
    final email = actorEmail ?? userEmail;
    final name = actorName ?? userName;
    if ((name ?? '').isNotEmpty && (email ?? '').isNotEmpty) {
      return '$name · $email';
    }
    if ((email ?? '').isNotEmpty) return email!;
    if ((name ?? '').isNotEmpty) return name!;
    return userId ?? 'System';
  }

  String get displayClub {
    if ((clubName ?? '').isNotEmpty) return clubName!;
    return clubId ?? '—';
  }

  String get displayTeam {
    if ((teamName ?? '').isNotEmpty) return teamName!;
    return teamId ?? '—';
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['userId']) ?? _asMap(json['user']);
    final actor = _asMap(json['actorUserId']) ?? _asMap(json['actorUser']);
    final club = _asMap(json['clubId']) ?? _asMap(json['club']);
    final team = _asMap(json['teamId']) ?? _asMap(json['team']);

    return AuditLogModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      action: (json['action'] ?? json['actionType'] ?? '').toString(),
      module: (json['module'] ?? '').toString(),
      entityType: (json['entityType'] ?? '').toString(),
      entityId: json['entityId']?.toString(),
      userId: _idFrom(json['userId'] ?? json['actorUserId']),
      userEmail: user?['email']?.toString(),
      userName: _fullName(user),
      actorEmail: actor?['email']?.toString(),
      actorName: _fullName(actor),
      userRole: json['userRole']?.toString(),
      clubId: _idFrom(json['clubId']),
      clubName: club?['name']?.toString(),
      teamId: _idFrom(json['teamId']),
      teamName: team?['name']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      route: json['route']?.toString(),
      method: json['method']?.toString(),
      statusCode: json['statusCode'] is num
          ? (json['statusCode'] as num).toInt()
          : null,
      durationMs: json['durationMs'] is num
          ? (json['durationMs'] as num).toInt()
          : null,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      suspicious: json['suspicious'] == true,
      suspiciousReason: json['suspiciousReason']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _idFrom(dynamic value) {
    if (value is Map) return (value['_id'] ?? value['id'])?.toString();
    return value?.toString();
  }

  static String? _fullName(Map<String, dynamic>? value) {
    if (value == null) return null;
    final explicit = value['fullName']?.toString();
    if (explicit != null && explicit.trim().isNotEmpty) return explicit.trim();
    final firstName = value['firstName']?.toString() ?? '';
    final lastName = value['lastName']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? null : name;
  }
}

class AuditLogsPage {
  AuditLogsPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AuditLogModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory AuditLogsPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final data = json['data'] as List<dynamic>? ?? const [];
    return AuditLogsPage(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(AuditLogModel.fromJson)
          .toList(),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? data.length,
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class AuditStatsModel {
  AuditStatsModel({
    required this.total,
    required this.last24h,
    required this.suspicious,
  });

  final int total;
  final int last24h;
  final int suspicious;

  factory AuditStatsModel.fromJson(Map<String, dynamic> json) {
    return AuditStatsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      last24h: (json['last24h'] as num?)?.toInt() ?? 0,
      suspicious: (json['suspicious'] as num?)?.toInt() ?? 0,
    );
  }
}

class SessionModel {
  SessionModel({
    required this.token,
    required this.userId,
    required this.role,
    required this.email,
    required this.status,
    required this.clubId,
    this.teamId,
    this.clubName,
    this.firstName,
    this.lastName,
    this.photoUrl,
  });

  final String token;
  final String userId;
  final String role;
  final String email;
  final String status;
  final String? clubId;
  final String? teamId;
  final String? clubName;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
}
