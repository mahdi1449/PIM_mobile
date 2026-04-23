class LearningModule {
  final String id;
  final String courseId;
  final String title;
  final String slug;
  final String description;
  final int order;
  final int lessonCount;
  final int completedLessons;

  const LearningModule({
    required this.id,
    required this.courseId,
    required this.title,
    required this.slug,
    required this.description,
    required this.order,
    required this.lessonCount,
    required this.completedLessons,
  });

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] as num).round()
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      lessonCount: (json['lessonCount'] ?? 0) is num
          ? (json['lessonCount'] as num).round()
          : int.tryParse((json['lessonCount'] ?? '0').toString()) ?? 0,
      completedLessons: (json['completedLessons'] ?? 0) is num
          ? (json['completedLessons'] as num).round()
          : int.tryParse((json['completedLessons'] ?? '0').toString()) ?? 0,
    );
  }
}

