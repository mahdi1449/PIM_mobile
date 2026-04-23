class LearningLesson {
  final String id;
  final String title;
  final String content;
  final String? videoUrl;
  final int order;
  final int quizCount;
  final int taskCount;
  final List<String> imageUrls;
  final bool completed;
  final bool suggestedForInjuryCommunication;

  const LearningLesson({
    required this.id,
    required this.title,
    required this.content,
    required this.videoUrl,
    required this.order,
    required this.quizCount,
    required this.taskCount,
    required this.imageUrls,
    required this.completed,
    required this.suggestedForInjuryCommunication,
  });

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    return LearningLesson(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      videoUrl: json['videoUrl']?.toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] as num).round()
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      quizCount: (json['quizCount'] ?? 0) is num
          ? (json['quizCount'] as num).round()
          : int.tryParse((json['quizCount'] ?? '0').toString()) ?? 0,
      taskCount: (json['taskCount'] ?? 0) is num
          ? (json['taskCount'] as num).round()
          : int.tryParse((json['taskCount'] ?? '0').toString()) ?? 0,
      imageUrls: (json['imageUrls'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      completed: json['completed'] == true,
      suggestedForInjuryCommunication:
          json['suggestedForInjuryCommunication'] == true,
    );
  }
}
