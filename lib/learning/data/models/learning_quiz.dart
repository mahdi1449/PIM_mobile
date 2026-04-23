class LearningQuizQuestion {
  final String id;
  final String lessonId;
  final String question;
  final List<String> options;

  const LearningQuizQuestion({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.options,
  });

  factory LearningQuizQuestion.fromJson(Map<String, dynamic> json) {
    return LearningQuizQuestion(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options:
          (json['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

class LearningQuizSubmitResult {
  final int score;
  final bool passed;
  final int correct;
  final int total;
  final List<dynamic>? results;

  const LearningQuizSubmitResult({
    required this.score,
    required this.passed,
    required this.correct,
    required this.total,
    this.results,
  });

  factory LearningQuizSubmitResult.fromJson(Map<String, dynamic> json) {
    return LearningQuizSubmitResult(
      score: (json['score'] ?? 0) is num ? (json['score'] as num).round() : 0,
      passed: json['passed'] == true,
      correct: (json['correct'] ?? 0) is num
          ? (json['correct'] as num).round()
          : 0,
      total: (json['total'] ?? 0) is num ? (json['total'] as num).round() : 0,
      results: json['results'] as List?,
    );
  }
}
