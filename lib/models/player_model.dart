class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.name,
    required this.position,
    required this.baseFitness,
    required this.injuryHistory,
    this.age = 0,
    this.speed = 0,
    this.endurance = 0,
    this.distance = 0,
    this.dribbles = 0,
    this.shots = 0,
    this.heartRate = 0,
    this.lastMatchId,
    this.lastMatchAt,
    this.lastMatchLoad,
    this.lastMatchFatigue,
    this.lastMatchInjuryProbability,
    this.isInjured,
    this.lastInjuryType,
    this.lastRecoveryDays,
    this.lastSeverity,
    this.lastInjuryProbability,
  });

  final String id;
  final String name;
  final String position;
  final int baseFitness;
  final int injuryHistory;
  final int age;
  final double speed;
  final double endurance;
  final double distance;
  final double dribbles;
  final double shots;
  final double heartRate;
  final String? lastMatchId;
  final DateTime? lastMatchAt;
  final int? lastMatchLoad;
  final int? lastMatchFatigue;
  final double? lastMatchInjuryProbability;
  final bool? isInjured;
  final String? lastInjuryType;
  final int? lastRecoveryDays;
  final String? lastSeverity;
  final double? lastInjuryProbability;

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final firstName = _stringFrom(json, ['firstName', 'first_name']);
    final lastName = _stringFrom(json, ['lastName', 'last_name']);
    final derivedName = [
      if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
      if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
    ].join(' ');

    return PlayerModel(
      id: _stringFrom(json, ['id', '_id', 'playerId']) ?? '',
      name:
          (_stringFrom(json, ['name', 'fullName', 'playerName']) ??
              (derivedName.isNotEmpty ? derivedName : null)) ??
          'Unknown',
      position: _stringFrom(json, ['position', 'role']) ?? 'Unknown',
      baseFitness: _intFrom(json, ['baseFitness', 'fitness', 'base_fitness']),
      injuryHistory: _intFrom(json, [
        'injuryHistory',
        'injuries',
        'injury_history',
      ]),
      age: _intFrom(json, ['age']),
      speed: (_doubleFrom(json, ['speed']) ?? 0),
      endurance: (_doubleFrom(json, ['endurance']) ?? 0),
      distance: (_doubleFrom(json, ['distance']) ?? 0),
      dribbles: (_doubleFrom(json, ['dribbles']) ?? 0),
      shots: (_doubleFrom(json, ['shots']) ?? 0),
      heartRate: (_doubleFrom(json, ['heart_rate', 'heartRate']) ?? 0),
      lastMatchId: _stringFrom(json, ['lastMatchId']),
      lastMatchAt: _dateFrom(json, ['lastMatchAt']),
      lastMatchLoad: _intFrom(json, ['lastMatchLoad']),
      lastMatchFatigue: _intFrom(json, ['lastMatchFatigue']),
      lastMatchInjuryProbability: _doubleFrom(json, [
        'lastMatchInjuryProbability',
      ]),
      isInjured: json['isInjured'] == true,
      lastInjuryType: _stringFrom(json, ['lastInjuryType']),
      lastRecoveryDays: _intFrom(json, ['lastRecoveryDays']),
      lastSeverity: _stringFrom(json, ['lastSeverity']),
      lastInjuryProbability: _doubleFrom(json, ['lastInjuryProbability']),
    );
  }

  static String? _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  static int _intFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static double? _doubleFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  static DateTime? _dateFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
