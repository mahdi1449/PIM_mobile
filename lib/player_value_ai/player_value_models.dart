class PlayerValueRequest {
  PlayerValueRequest({
    required this.speed,
    required this.endurance,
    required this.distance,
    required this.dribbles,
    required this.shots,
    required this.injuries,
    required this.heartRate,
    required this.age,
    required this.recoveryTime,
    required this.fitnessLevel,
    required this.medicalRiskScore,
    required this.minutesPlayed,
    required this.goals,
    required this.assists,
    required this.ratingPerMatch,
    required this.consistencyScore,
  });

  final double speed;
  final double endurance;
  final double distance;
  final double dribbles;
  final double shots;
  final int injuries;
  final double heartRate;
  final int age;
  final double recoveryTime;
  final double fitnessLevel;
  final double medicalRiskScore;
  final int minutesPlayed;
  final int goals;
  final int assists;
  final double ratingPerMatch;
  final double consistencyScore;

  Map<String, dynamic> toJson() => {
    'speed': speed,
    'endurance': endurance,
    'distance': distance,
    'dribbles': dribbles,
    'shots': shots,
    'injuries': injuries,
    'heart_rate': heartRate,
    'age': age,
    'recoveryTime': recoveryTime,
    'fitnessLevel': fitnessLevel,
    'medicalRiskScore': medicalRiskScore,
    'minutesPlayed': minutesPlayed,
    'goals': goals,
    'assists': assists,
    'ratingPerMatch': ratingPerMatch,
    'consistencyScore': consistencyScore,
  };
}

class PlayerValueResponse {
  PlayerValueResponse({
    required this.predictedValue,
    required this.nextSeasonValue,
    required this.confidenceScore,
    required this.keyFactors,
    required this.explanation,
    required this.currency,
  });

  final double predictedValue;
  final double nextSeasonValue;
  final double confidenceScore;
  final List<String> keyFactors;
  final String explanation;
  final String currency;

  factory PlayerValueResponse.fromJson(Map<String, dynamic> json) {
    return PlayerValueResponse(
      predictedValue: (json['predicted_value'] as num).toDouble(),
      nextSeasonValue: (json['next_season_value'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      keyFactors: (json['key_factors'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      explanation: (json['explanation'] as String),
      currency: (json['currency'] as String?) ?? 'EUR',
    );
  }
}
