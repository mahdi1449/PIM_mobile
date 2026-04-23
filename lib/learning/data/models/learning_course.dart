class LearningCourse {
  final String id;
  final String title;
  final String description;
  final String level;
  final String type;
  final String? thumbnailUrl;
  final int progressPercentage;
  final bool completed;
  final bool recommended;
  final List<String> recommendedReasons;
  final int quizAverage;

  const LearningCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.type,
    required this.thumbnailUrl,
    required this.progressPercentage,
    required this.completed,
    required this.recommended,
    required this.recommendedReasons,
    required this.quizAverage,
  });

  factory LearningCourse.fromJson(Map<String, dynamic> json) {
    return LearningCourse(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      progressPercentage: (json['progressPercentage'] ?? 0) is num
          ? (json['progressPercentage'] as num).round()
          : int.tryParse((json['progressPercentage'] ?? '0').toString()) ?? 0,
      completed: json['completed'] == true,
      recommended: json['recommended'] == true,
      recommendedReasons:
          (json['recommendedReasons'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      quizAverage: (json['quizAverage'] ?? 0) is num
          ? (json['quizAverage'] as num).round()
          : int.tryParse((json['quizAverage'] ?? '0').toString()) ?? 0,
    );
  }
}
