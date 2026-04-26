import 'package:intl/intl.dart';

class GamificationProfile {
  final String userId;
  final int totalPoints;
  final int monthlyPoints;
  final String currentLevel;
  final int activeStreak;
  final DateTime? lastActionDate;

  GamificationProfile({
    required this.userId,
    required this.totalPoints,
    required this.monthlyPoints,
    required this.currentLevel,
    required this.activeStreak,
    this.lastActionDate,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      userId: json['userId'] ?? '',
      totalPoints: json['totalPoints'] ?? 0,
      monthlyPoints: json['monthlyPoints'] ?? 0,
      currentLevel: json['currentLevel'] ?? 'Recrue',
      activeStreak: json['activeStreak'] ?? 0,
      lastActionDate: json['lastActionDate'] != null ? DateTime.parse(json['lastActionDate']) : null,
    );
  }

  double get progression {
    if (totalPoints >= 8000) return 1.0;
    if (totalPoints >= 3500) return (totalPoints - 3500) / (8000 - 3500);
    if (totalPoints >= 1000) return (totalPoints - 1000) / (3500 - 1000);
    return totalPoints / 1000;
  }

  String get nextLevel {
    if (totalPoints >= 8000) return 'Légende (Max)';
    if (totalPoints >= 3500) return 'Légende';
    if (totalPoints >= 1000) return 'Elite';
    return 'Pro';
  }

  int get targetPoints {
    if (totalPoints >= 3500) return 8000;
    if (totalPoints >= 1000) return 3500;
    return 1000;
  }
}

class ActionLog {
  final String type;
  final String module;
  final int points;
  final String timeAgo;

  ActionLog({
    required this.type,
    required this.module,
    required this.points,
    required this.timeAgo,
  });

  factory ActionLog.fromJson(Map<String, dynamic> json) {
    return ActionLog(
      type: json['actionType'] ?? '',
      module: json['moduleId'] ?? '',
      points: json['points'] ?? 0,
      timeAgo: 'il y a quelques heures',
    );
  }
}
