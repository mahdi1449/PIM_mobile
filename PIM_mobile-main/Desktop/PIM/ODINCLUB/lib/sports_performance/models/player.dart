// Player Statistics Model
class PlayerStatistics {
  final int totalEvents;
  final double averageScore;
  final double bestScore;
  final String? rank;

  PlayerStatistics({
    required this.totalEvents,
    required this.averageScore,
    required this.bestScore,
    this.rank,
  });

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      totalEvents: json['totalEvents'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      bestScore: (json['bestScore'] ?? 0).toDouble(),
      rank: json['rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEvents': totalEvents,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'rank': rank,
    };
  }
}

// Player Model
class Player {
  final String id;
  final String? userId;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String position;
  final String strongFoot;
  final int? jerseyNumber;
  final double? height;
  final double? weight;
  final String? photo;
  final String? nationality;
  final PlayerStatistics? statistics;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Player({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.position,
    required this.strongFoot,
    this.jerseyNumber,
    this.height,
    this.weight,
    this.photo,
    this.nationality,
    this.statistics,
    this.createdAt,
    this.updatedAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      position: json['position'],
      strongFoot: json['strongFoot'] ?? 'Right', // Default to Right if missing
      jerseyNumber: json['jerseyNumber'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      photo: json['photo'],
      nationality: json['nationality'],
      statistics: json['statistics'] != null
          ? PlayerStatistics.fromJson(json['statistics'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
     final Map<String, dynamic> data = {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'position': position,
      'strongFoot': strongFoot,
      'jerseyNumber': jerseyNumber,
      'height': height,
      'weight': weight,
      'photo': photo,
      'nationality': nationality,
    };

    if (statistics != null) {
      data['statistics'] = statistics!.toJson();
    }

    return data;
  }

  String get fullName => '$firstName $lastName';
  
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
