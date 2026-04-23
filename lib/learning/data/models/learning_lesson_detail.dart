class LearningLessonDetail {
  final Map<String, dynamic> lesson;
  final List<LearningLessonSection> sections;
  final List<LearningVocabularyItem> vocabulary;
  final List<LearningExercise> exercises;

  const LearningLessonDetail({
    required this.lesson,
    required this.sections,
    required this.vocabulary,
    required this.exercises,
  });

  factory LearningLessonDetail.fromJson(Map<String, dynamic> json) {
    return LearningLessonDetail(
      lesson: Map<String, dynamic>.from(json['lesson'] as Map? ?? const {}),
      sections: (json['sections'] as List? ?? const [])
          .map((e) => LearningLessonSection.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      vocabulary: (json['vocabulary'] as List? ?? const [])
          .map((e) => LearningVocabularyItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      exercises: (json['exercises'] as List? ?? const [])
          .map((e) => LearningExercise.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LearningLessonSection {
  final String id;
  final String title;
  final int order;
  final List<LearningLessonBlock> blocks;

  const LearningLessonSection({
    required this.id,
    required this.title,
    required this.order,
    required this.blocks,
  });

  factory LearningLessonSection.fromJson(Map<String, dynamic> json) {
    return LearningLessonSection(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] as num).round()
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      blocks: (json['blocks'] as List? ?? const [])
          .map((e) => LearningLessonBlock.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LearningLessonBlock {
  final String type;
  final String? title;
  final String? text;
  final List<String> items;

  const LearningLessonBlock({
    required this.type,
    required this.title,
    required this.text,
    required this.items,
  });

  factory LearningLessonBlock.fromJson(Map<String, dynamic> json) {
    return LearningLessonBlock(
      type: (json['type'] ?? 'text').toString(),
      title: json['title']?.toString(),
      text: json['text']?.toString(),
      items: (json['items'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

class LearningVocabularyItem {
  final String id;
  final String term;
  final String definition;
  final String example;
  final Map<String, dynamic> notes;

  const LearningVocabularyItem({
    required this.id,
    required this.term,
    required this.definition,
    required this.example,
    required this.notes,
  });

  factory LearningVocabularyItem.fromJson(Map<String, dynamic> json) {
    return LearningVocabularyItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      definition: (json['definition'] ?? '').toString(),
      example: (json['example'] ?? '').toString(),
      notes: json['notes'] is Map ? Map<String, dynamic>.from(json['notes'] as Map) : <String, dynamic>{},
    );
  }
}

class LearningExercise {
  final String id;
  final String lessonId;
  final String type;
  final String title;
  final String instructions;
  final String prompt;
  final int order;
  final bool graded;
  final int passScore;
  final Map<String, dynamic> payload;
  final List<LearningQuestion> questions;
  final Map<String, dynamic>? latestAttempt;

  const LearningExercise({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.title,
    required this.instructions,
    required this.prompt,
    required this.order,
    required this.graded,
    required this.passScore,
    required this.payload,
    required this.questions,
    required this.latestAttempt,
  });

  factory LearningExercise.fromJson(Map<String, dynamic> json) {
    return LearningExercise(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      type: (json['type'] ?? 'open_text').toString(),
      title: (json['title'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      order: (json['order'] ?? 0) is num
          ? (json['order'] as num).round()
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      graded: json['graded'] == true,
      passScore: (json['passScore'] ?? 70) is num
          ? (json['passScore'] as num).round()
          : int.tryParse((json['passScore'] ?? '70').toString()) ?? 70,
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : <String, dynamic>{},
      questions: (json['questions'] as List? ?? const [])
          .map((e) => LearningQuestion.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      latestAttempt: json['latestAttempt'] is Map
          ? Map<String, dynamic>.from(json['latestAttempt'] as Map)
          : null,
    );
  }
}

class LearningQuestion {
  final String id;
  final String type;
  final String prompt;
  final List<LearningAnswerOption> options;

  const LearningQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
  });

  factory LearningQuestion.fromJson(Map<String, dynamic> json) {
    return LearningQuestion(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      options: (json['options'] as List? ?? const [])
          .map((e) => LearningAnswerOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LearningAnswerOption {
  final String id;
  final String text;

  const LearningAnswerOption({required this.id, required this.text});

  factory LearningAnswerOption.fromJson(Map<String, dynamic> json) {
    return LearningAnswerOption(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

