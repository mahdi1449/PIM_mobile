class LearningTask {
  final String id;
  final String lessonId;
  final String title;
  final String instructions;
  final String kind;
  final int order;
  final List<String> tags;
  final Map<String, dynamic> payload;

  const LearningTask({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.instructions,
    required this.kind,
    required this.order,
    required this.tags,
    required this.payload,
  });

  factory LearningTask.fromJson(Map<String, dynamic> json) {
    return LearningTask(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      kind: (json['kind'] ?? 'open').toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] as num).round()
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      tags: (json['tags'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
    );
  }
}
