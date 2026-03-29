class CognitiveScores {
  final int reactionScore;
  final int focusScore;
  final int memoryScore;
  final int mentalScore;
  final int? decisionScore;
  final int? wellnessScore;
  final String? trainingReadiness;

  CognitiveScores({
    required this.reactionScore,
    required this.focusScore,
    required this.memoryScore,
    required this.mentalScore,
    this.decisionScore,
    this.wellnessScore,
    this.trainingReadiness,
  });

  factory CognitiveScores.fromJson(Map<String, dynamic> json) {
    return CognitiveScores(
      reactionScore: json['reactionScore'] ?? 0,
      focusScore: json['focusScore'] ?? 0,
      memoryScore: json['memoryScore'] ?? 0,
      mentalScore: json['mentalScore'] ?? 0,
      decisionScore: json['decisionScore'],
      wellnessScore: json['wellnessScore'],
      trainingReadiness: json['trainingReadiness'],
    );
  }
}

class ReactionMetrics {
  final int avgMs;
  final int bestMs;
  final int worstMs;
  final int accuracy;

  ReactionMetrics({
    required this.avgMs,
    required this.bestMs,
    required this.worstMs,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'avgMs': avgMs,
    'bestMs': bestMs,
    'worstMs': worstMs,
    'accuracy': accuracy,
  };
}

class FocusMetrics {
  final int completionTime;
  final int errors;

  FocusMetrics({
    required this.completionTime,
    required this.errors,
  });

  Map<String, dynamic> toJson() => {
    'completionTime': completionTime,
    'errors': errors,
  };
}

class MemoryMetrics {
  final int correctSequences;
  final int failures;
  final int maxLevel;

  MemoryMetrics({
    required this.correctSequences,
    required this.failures,
    required this.maxLevel,
  });

  Map<String, dynamic> toJson() => {
    'correctSequences': correctSequences,
    'failures': failures,
    'maxLevel': maxLevel,
  };
}

class CognitiveSession {
  final String id;
  final String playerId;
  final DateTime date;
  
  final CognitiveScores? scores;
  final String? aiStatus;
  final String? riskLevel;
  final String? aiRecommendationText;
  final String? trainingSuggestion;

  CognitiveSession({
    required this.id,
    required this.playerId,
    required this.date,
    this.scores,
    this.aiStatus,
    this.riskLevel,
    this.aiRecommendationText,
    this.trainingSuggestion,
  });

  factory CognitiveSession.fromJson(Map<String, dynamic> json) {
    return CognitiveSession(
      id: json['_id'] ?? '',
      playerId: json['playerId'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      scores: json['scores'] != null ? CognitiveScores.fromJson(json['scores']) : null,
      aiStatus: json['aiStatus'],
      riskLevel: json['riskLevel'],
      aiRecommendationText: json['aiRecommendationText'],
      trainingSuggestion: json['trainingSuggestion'],
    );
  }
}
