class LearningProgress {
  final String id;
  final String playerId;
  final String courseId;
  final int progressPercentage;
  final bool completed;
  final int quizAverage;
  final Map<String, dynamic>? course;

  const LearningProgress({
    required this.id,
    required this.playerId,
    required this.courseId,
    required this.progressPercentage,
    required this.completed,
    required this.quizAverage,
    required this.course,
  });

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    final course = json['courseId'];
    return LearningProgress(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
      courseId: course is Map
          ? (course['_id'] ?? '').toString()
          : (json['courseId'] ?? '').toString(),
      progressPercentage: (json['progressPercentage'] ?? 0) is num
          ? (json['progressPercentage'] as num).round()
          : int.tryParse((json['progressPercentage'] ?? '0').toString()) ?? 0,
      completed: json['completed'] == true,
      quizAverage: (json['quizAverage'] ?? 0) is num
          ? (json['quizAverage'] as num).round()
          : int.tryParse((json['quizAverage'] ?? '0').toString()) ?? 0,
      course: course is Map ? Map<String, dynamic>.from(course) : null,
    );
  }
}
