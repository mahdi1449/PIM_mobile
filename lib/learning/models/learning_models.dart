class LearningCourse {
  LearningCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.type,
    required this.tags,
    required this.recommendedPositions,
    required this.estimatedMinutes,
    required this.lessonCount,
    this.slug,
    this.thumbnailUrl,
    this.badgeName,
    this.progress,
    this.score,
    this.reasons = const [],
  });

  final String id;
  final String? slug;
  final String title;
  final String description;
  final String level;
  final String type;
  final List<String> tags;
  final List<String> recommendedPositions;
  final int estimatedMinutes;
  final int lessonCount;
  final String? thumbnailUrl;
  final String? badgeName;
  final LearningProgress? progress;
  final int? score;
  final List<String> reasons;

  int get progressPercent => progress?.progressPercentage ?? 0;

  factory LearningCourse.fromJson(Map<String, dynamic> json) {
    return LearningCourse(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      slug: json['slug']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      tags: _stringList(json['tags']),
      recommendedPositions: _stringList(json['recommendedPositions']),
      estimatedMinutes: _toInt(json['estimatedMinutes']),
      lessonCount: _toInt(json['lessonCount']),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      badgeName: json['badgeName']?.toString(),
      progress: json['progress'] is Map<String, dynamic>
          ? LearningProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      score: json['score'] == null ? null : _toInt(json['score']),
      reasons: (json['reasons'] is List)
          ? (json['reasons'] as List)
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return (item['label'] ?? '').toString();
                  }
                  return item.toString();
                })
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class LearningLesson {
  LearningLesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.order,
    required this.durationMinutes,
    required this.moduleLabel,
    required this.focusScore,
    required this.vocabulary,
    required this.transcript,
    required this.sourcePageImages,
    this.videoUrl,
    this.pageStart,
    this.pageEnd,
    this.injuryCommunication = false,
  });

  final String id;
  final String courseId;
  final String title;
  final String content;
  final int order;
  final int durationMinutes;
  final String moduleLabel;
  final int focusScore;
  final String? videoUrl;
  final int? pageStart;
  final int? pageEnd;
  final List<String> vocabulary;
  final List<TranscriptSegment> transcript;
  final List<String> sourcePageImages;
  final bool injuryCommunication;

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    return LearningLesson(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      order: _toInt(json['order']),
      durationMinutes: _toInt(json['durationMinutes']),
      moduleLabel: (json['moduleLabel'] ?? 'Module').toString(),
      focusScore: _toInt(json['focusScore']),
      videoUrl: json['videoUrl']?.toString(),
      pageStart: json['pageStart'] == null ? null : _toInt(json['pageStart']),
      pageEnd: json['pageEnd'] == null ? null : _toInt(json['pageEnd']),
      vocabulary: _stringList(json['vocabulary']),
      transcript: (json['transcript'] is List)
          ? (json['transcript'] as List)
                .whereType<Map<String, dynamic>>()
                .map(TranscriptSegment.fromJson)
                .toList()
          : const [],
      injuryCommunication: json['injuryCommunication'] == true,
      sourcePageImages: _stringList(json['sourcePageImages']),
    );
  }
}

class TranscriptSegment {
  TranscriptSegment({
    required this.time,
    required this.text,
    required this.current,
  });

  final String time;
  final String text;
  final bool current;

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptSegment(
      time: (json['time'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      current: json['current'] == true,
    );
  }
}

class LearningProgress {
  LearningProgress({
    required this.id,
    required this.playerId,
    required this.courseId,
    required this.progressPercentage,
    required this.completed,
    required this.completedLessons,
    this.lastLessonId,
    this.earnedBadge,
    this.course,
  });

  final String id;
  final String playerId;
  final String courseId;
  final int progressPercentage;
  final bool completed;
  final List<String> completedLessons;
  final String? lastLessonId;
  final String? earnedBadge;
  final LearningCourse? course;

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      progressPercentage: _toInt(json['progressPercentage']),
      completed: json['completed'] == true,
      completedLessons: _stringList(json['completedLessons']),
      lastLessonId: json['lastLessonId']?.toString(),
      earnedBadge: json['earnedBadge']?.toString(),
      course: json['course'] is Map<String, dynamic>
          ? LearningCourse.fromJson(json['course'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LearningQuizQuestion {
  LearningQuizQuestion({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.options,
    this.explanation,
  });

  final String id;
  final String lessonId;
  final String question;
  final List<String> options;
  final String? explanation;

  factory LearningQuizQuestion.fromJson(Map<String, dynamic> json) {
    return LearningQuizQuestion(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options: _stringList(json['options']),
      explanation: json['explanation']?.toString(),
    );
  }
}

class QuizResult {
  QuizResult({
    required this.scorePercentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.passed,
  });

  final int scorePercentage;
  final int correctAnswers;
  final int totalQuestions;
  final bool passed;

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      scorePercentage: _toInt(json['scorePercentage']),
      correctAnswers: _toInt(json['correctAnswers']),
      totalQuestions: _toInt(json['totalQuestions']),
      passed: json['passed'] == true,
    );
  }
}

class LearningExercise {
  LearningExercise({
    required this.id,
    required this.externalId,
    required this.lessonObjectId,
    required this.type,
    required this.interactionType,
    required this.title,
    required this.prompt,
    required this.questions,
    required this.options,
    required this.assets,
    required this.matching,
    required this.fillBlanks,
    this.sourcePageImage,
    this.page,
    this.answerKey,
  });

  final String id;
  final String externalId;
  final String lessonObjectId;
  final String type;
  final String interactionType;
  final String title;
  final String prompt;
  final List<String> questions;
  final List<String> options;
  final List<LearningExerciseAsset> assets;
  final MatchingExercise? matching;
  final List<FillBlankItem> fillBlanks;
  final String? sourcePageImage;
  final int? page;
  final dynamic answerKey;

  bool get isMatching => interactionType == 'drag_drop_matching';
  bool get isFillBlank => type == 'fill_blank' && fillBlanks.isNotEmpty;

  factory LearningExercise.fromJson(Map<String, dynamic> json) {
    return LearningExercise(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      externalId: (json['externalId'] ?? json['_id'] ?? '').toString(),
      lessonObjectId: (json['lessonObjectId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      interactionType: (json['interactionType'] ?? json['type'] ?? '')
          .toString(),
      title: (json['title'] ?? 'Exercise').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      questions: _stringList(json['questions']),
      options: _stringList(json['options']),
      assets: (json['assets'] is List)
          ? (json['assets'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LearningExerciseAsset.fromJson)
                .toList()
          : const [],
      matching: json['matching'] is Map<String, dynamic>
          ? MatchingExercise.fromJson(json['matching'] as Map<String, dynamic>)
          : null,
      fillBlanks: (json['fillBlanks'] is List)
          ? (json['fillBlanks'] as List)
                .whereType<Map<String, dynamic>>()
                .map(FillBlankItem.fromJson)
                .toList()
          : const [],
      sourcePageImage: json['sourcePageImage']?.toString(),
      page: json['page'] == null ? null : _toInt(json['page']),
      answerKey: json['answerKey'],
    );
  }
}

class LearningExerciseAsset {
  LearningExerciseAsset({required this.type, required this.url, this.purpose});

  final String type;
  final String url;
  final String? purpose;

  factory LearningExerciseAsset.fromJson(Map<String, dynamic> json) {
    return LearningExerciseAsset(
      type: (json['type'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      purpose: json['purpose']?.toString(),
    );
  }
}

class MatchingExercise {
  MatchingExercise({
    required this.left,
    required this.right,
    required this.answerMap,
    required this.manualCorrection,
  });

  final List<MatchingItem> left;
  final List<MatchingItem> right;
  final Map<String, String> answerMap;
  final bool manualCorrection;

  factory MatchingExercise.fromJson(Map<String, dynamic> json) {
    final rawAnswerMap = json['answerMap'] is Map<String, dynamic>
        ? json['answerMap'] as Map<String, dynamic>
        : <String, dynamic>{};
    return MatchingExercise(
      left: (json['left'] is List)
          ? (json['left'] as List)
                .whereType<Map<String, dynamic>>()
                .map(MatchingItem.fromJson)
                .toList()
          : const [],
      right: (json['right'] is List)
          ? (json['right'] as List)
                .whereType<Map<String, dynamic>>()
                .map(MatchingItem.fromJson)
                .toList()
          : const [],
      answerMap: rawAnswerMap.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      manualCorrection: json['manualCorrection'] == true,
    );
  }
}

class MatchingItem {
  MatchingItem({required this.id, required this.label, this.imageUrl});

  final String id;
  final String label;
  final String? imageUrl;

  factory MatchingItem.fromJson(Map<String, dynamic> json) {
    return MatchingItem(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class FillBlankItem {
  FillBlankItem({
    required this.id,
    required this.sentence,
    required this.answers,
    this.imageUrl,
    this.hint,
  });

  final String id;
  final String sentence;
  final List<String> answers;
  final String? imageUrl;
  final String? hint;

  factory FillBlankItem.fromJson(Map<String, dynamic> json) {
    return FillBlankItem(
      id: (json['id'] ?? '').toString(),
      sentence: (json['sentence'] ?? '').toString(),
      answers: _stringList(json['answers']),
      imageUrl: json['imageUrl']?.toString(),
      hint: json['hint']?.toString(),
    );
  }
}

class LearningDashboard {
  LearningDashboard({
    required this.playerName,
    required this.position,
    required this.communicationScore,
    required this.completedCourses,
    required this.activeCourses,
    required this.averageProgress,
    required this.certificates,
    required this.recommendations,
    required this.weakPoints,
  });

  final String playerName;
  final String position;
  final int communicationScore;
  final int completedCourses;
  final int activeCourses;
  final int averageProgress;
  final List<String> certificates;
  final List<LearningCourse> recommendations;
  final List<Map<String, dynamic>> weakPoints;

  factory LearningDashboard.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] is Map<String, dynamic>
        ? json['progress'] as Map<String, dynamic>
        : <String, dynamic>{};
    final player = json['player'] is Map<String, dynamic>
        ? json['player'] as Map<String, dynamic>
        : <String, dynamic>{};

    return LearningDashboard(
      playerName: (player['name'] ?? 'ODIN Player').toString(),
      position: (player['position'] ?? 'Player').toString(),
      communicationScore: _toInt(json['communicationScore']),
      completedCourses: _toInt(progress['completedCourses']),
      activeCourses: _toInt(progress['activeCourses']),
      averageProgress: _toInt(progress['averageProgress']),
      certificates: (progress['certificates'] is List)
          ? (progress['certificates'] as List)
                .whereType<Map<String, dynamic>>()
                .map((item) => (item['badgeName'] ?? '').toString())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      recommendations: (json['recommendations'] is List)
          ? (json['recommendations'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LearningCourse.fromJson)
                .toList()
          : const [],
      weakPoints: (json['weakPoints'] is List)
          ? (json['weakPoints'] as List)
                .whereType<Map<String, dynamic>>()
                .toList()
          : const [],
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
