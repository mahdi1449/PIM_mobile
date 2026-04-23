class LearningLessonSummary {
  final String id;
  final String courseId;
  final String? moduleId;
  final String title;
  final String slug;
  final String introPrompt;
  final int order;
  final List<String> tags;
  final String? videoUrl;
  final List<String> imageUrls;
  final int exerciseCount;
  final bool completed;

  const LearningLessonSummary({
    required this.id,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.slug,
    required this.introPrompt,
    required this.order,
    required this.tags,
    required this.videoUrl,
    required this.imageUrls,
    required this.exerciseCount,
    required this.completed,
  });

  factory LearningLessonSummary.fromJson(Map<String, dynamic> json) {
    return LearningLessonSummary(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      moduleId: json['moduleId']?.toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      introPrompt: (json['introPrompt'] ?? '').toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] as num).round()
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      tags: (json['tags'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      videoUrl: json['videoUrl']?.toString(),
      imageUrls: (json['imageUrls'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      exerciseCount: (json['exerciseCount'] ?? 0) is num
          ? (json['exerciseCount'] as num).round()
          : int.tryParse((json['exerciseCount'] ?? '0').toString()) ?? 0,
      completed: json['completed'] == true,
    );
  }
}

