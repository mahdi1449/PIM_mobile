class MediaTrainingDashboard {
  MediaTrainingDashboard({
    required this.communicationTier,
    required this.communicationProfile,
    required this.roadmapSummary,
    this.currentLesson,
    required this.recentSessions,
  });

  final String communicationTier;
  final Map<String, double?> communicationProfile;
  final MediaTrainingRoadmapSummary roadmapSummary;
  final MediaTrainingLesson? currentLesson;
  final List<MediaTrainingSessionSummary> recentSessions;

  factory MediaTrainingDashboard.fromJson(Map<String, dynamic> json) {
    final profileJson =
        (json['communicationProfile'] as Map?)?.cast<String, dynamic>() ?? {};
    return MediaTrainingDashboard(
      communicationTier: (json['communicationTier'] ?? 'STARTER').toString(),
      communicationProfile: {
        'clarity': _toDouble(profileJson['clarity']),
        'messageControl': _toDouble(profileJson['messageControl']),
        'emotionalControl': _toDouble(profileJson['emotionalControl']),
        'discipline': _toDouble(profileJson['discipline']),
        'structure': _toDouble(profileJson['structure']),
        'pressureManagement': _toDouble(profileJson['pressureManagement']),
      },
      roadmapSummary: MediaTrainingRoadmapSummary.fromJson(
        (json['roadmapSummary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      currentLesson: json['currentLesson'] is Map<String, dynamic>
          ? MediaTrainingLesson.fromJson(
              json['currentLesson'] as Map<String, dynamic>)
          : null,
      recentSessions: _toList(json['recentSessions'])
          .map((item) => MediaTrainingSessionSummary.fromJson(item))
          .toList(),
    );
  }
}

class MediaTrainingRoadmap {
  MediaTrainingRoadmap({
    required this.summary,
    required this.phases,
    required this.lessons,
  });

  final MediaTrainingRoadmapSummary summary;
  final List<MediaTrainingPhase> phases;
  final List<MediaTrainingLesson> lessons;

  factory MediaTrainingRoadmap.fromJson(Map<String, dynamic> json) {
    return MediaTrainingRoadmap(
      summary: MediaTrainingRoadmapSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      phases: _toList(json['phases'])
          .map((item) => MediaTrainingPhase.fromJson(item))
          .toList(),
      lessons: _toList(json['lessons'])
          .map((item) => MediaTrainingLesson.fromJson(item))
          .toList(),
    );
  }
}

class MediaTrainingRoadmapSummary {
  MediaTrainingRoadmapSummary({
    required this.totalLessons,
    required this.completedLessons,
    required this.masteredLessons,
    required this.lockedLessons,
    required this.progressPercent,
    required this.masteryPercent,
    this.nextRecommendedLessonId,
    this.nextRecommendedLessonTitle,
  });

  final int totalLessons;
  final int completedLessons;
  final int masteredLessons;
  final int lockedLessons;
  final double progressPercent;
  final double masteryPercent;
  final String? nextRecommendedLessonId;
  final String? nextRecommendedLessonTitle;

  factory MediaTrainingRoadmapSummary.fromJson(Map<String, dynamic> json) {
    return MediaTrainingRoadmapSummary(
      totalLessons: _toInt(json['totalLessons']),
      completedLessons: _toInt(json['completedLessons']),
      masteredLessons: _toInt(json['masteredLessons']),
      lockedLessons: _toInt(json['lockedLessons']),
      progressPercent: _toDouble(json['progressPercent']) ?? 0,
      masteryPercent: _toDouble(json['masteryPercent']) ?? 0,
      nextRecommendedLessonId: json['nextRecommendedLessonId']?.toString(),
      nextRecommendedLessonTitle:
          json['nextRecommendedLessonTitle']?.toString(),
    );
  }
}

class MediaTrainingPhase {
  MediaTrainingPhase({
    required this.phase,
    required this.lessons,
    required this.progressPercent,
    required this.completed,
    required this.mastered,
  });

  final String phase;
  final List<MediaTrainingLesson> lessons;
  final double progressPercent;
  final int completed;
  final int mastered;

  factory MediaTrainingPhase.fromJson(Map<String, dynamic> json) {
    final totals =
        (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MediaTrainingPhase(
      phase: (json['phase'] ?? '').toString(),
      lessons: _toList(json['lessons'])
          .map((item) => MediaTrainingLesson.fromJson(item))
          .toList(),
      progressPercent: _toDouble(totals['progressPercent']) ?? 0,
      completed: _toInt(totals['completed']),
      mastered: _toInt(totals['mastered']),
    );
  }
}

class MediaTrainingLesson {
  MediaTrainingLesson({
    required this.id,
    required this.title,
    required this.format,
    required this.level,
    required this.order,
    required this.phase,
    required this.summary,
    required this.estimatedMinutes,
    required this.focus,
    required this.skillTags,
    required this.objectives,
    required this.coachBrief,
    required this.talkingPointsTemplate,
    required this.doList,
    required this.avoidList,
    required this.lessonBlocks,
    required this.masteryThreshold,
    required this.unlockAfterLessonIds,
    required this.masteryRules,
    required this.completed,
    required this.mastered,
    required this.unlocked,
    required this.attempts,
    required this.evaluatedAttempts,
    this.lockedReason,
    this.bestScore,
    this.latestScore,
    required this.weakSkills,
    this.recommendedAction,
    this.nextSimulationCase,
    required this.simulationPreview,
  });

  final String id;
  final String title;
  final String format;
  final String level;
  final int order;
  final String phase;
  final String summary;
  final int estimatedMinutes;
  final String focus;
  final List<String> skillTags;
  final List<String> objectives;
  final String coachBrief;
  final List<String> talkingPointsTemplate;
  final List<String> doList;
  final List<String> avoidList;
  final List<MediaLessonBlock> lessonBlocks;
  final double masteryThreshold;
  final List<String> unlockAfterLessonIds;
  final List<MediaLessonMasteryRule> masteryRules;
  final bool completed;
  final bool mastered;
  final bool unlocked;
  final int attempts;
  final int evaluatedAttempts;
  final String? lockedReason;
  final double? bestScore;
  final double? latestScore;
  final List<String> weakSkills;
  final String? recommendedAction;
  final MediaSimulationCasePreview? nextSimulationCase;
  final List<MediaSimulationQuestion> simulationPreview;

  factory MediaTrainingLesson.fromJson(Map<String, dynamic> json) {
    return MediaTrainingLesson(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      format: (json['format'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      order: _toInt(json['order']),
      phase: (json['phase'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      estimatedMinutes: _toInt(json['estimatedMinutes']),
      focus: (json['focus'] ?? '').toString(),
      skillTags: _toStringList(json['skillTags']),
      objectives: _toStringList(json['objectives']),
      coachBrief: (json['coachBrief'] ?? '').toString(),
      talkingPointsTemplate: _toStringList(json['talkingPointsTemplate']),
      doList: _toStringList(json['doList']),
      avoidList: _toStringList(json['avoidList']),
      lessonBlocks: _toList(json['lessonBlocks'])
          .map((item) => MediaLessonBlock.fromJson(item))
          .toList(),
      masteryThreshold: _toDouble(json['masteryThreshold']) ?? 0,
      unlockAfterLessonIds: _toStringList(json['unlockAfterLessonIds']),
      masteryRules: _toList(json['masteryRules'])
          .map((item) => MediaLessonMasteryRule.fromJson(item))
          .toList(),
      completed: json['completed'] == true,
      mastered: json['mastered'] == true,
      unlocked: json['unlocked'] != false,
      attempts: _toInt(json['attempts']),
      evaluatedAttempts: _toInt(json['evaluatedAttempts']),
      lockedReason: json['lockedReason']?.toString(),
      bestScore: _toDouble(json['bestScore']),
      latestScore: _toDouble(json['latestScore']),
      weakSkills: _toStringList(json['weakSkills']),
      recommendedAction: json['recommendedAction']?.toString(),
      nextSimulationCase: json['nextSimulationCase'] is Map<String, dynamic>
          ? MediaSimulationCasePreview.fromJson(
              json['nextSimulationCase'] as Map<String, dynamic>)
          : null,
      simulationPreview: _toList(json['simulationPreview'])
          .map((item) => MediaSimulationQuestion.fromJson(item))
          .toList(),
    );
  }
}

class MediaLessonBlock {
  MediaLessonBlock({
    required this.id,
    required this.title,
    required this.summary,
    required this.keyTakeaways,
    required this.coachPrompt,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> keyTakeaways;
  final String coachPrompt;

  factory MediaLessonBlock.fromJson(Map<String, dynamic> json) {
    return MediaLessonBlock(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      keyTakeaways: _toStringList(json['keyTakeaways']),
      coachPrompt: (json['coachPrompt'] ?? '').toString(),
    );
  }
}

class MediaLessonMasteryRule {
  MediaLessonMasteryRule({
    required this.metric,
    required this.minimum,
    required this.label,
  });

  final String metric;
  final double minimum;
  final String label;

  factory MediaLessonMasteryRule.fromJson(Map<String, dynamic> json) {
    return MediaLessonMasteryRule(
      metric: (json['metric'] ?? '').toString(),
      minimum: _toDouble(json['minimum']) ?? 0,
      label: (json['label'] ?? '').toString(),
    );
  }
}

class MediaSimulationCasePreview {
  MediaSimulationCasePreview({
    required this.id,
    required this.label,
    required this.context,
    required this.journalistAngle,
    required this.pressureLevel,
  });

  final String id;
  final String label;
  final String context;
  final String journalistAngle;
  final int pressureLevel;

  factory MediaSimulationCasePreview.fromJson(Map<String, dynamic> json) {
    return MediaSimulationCasePreview(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      context: (json['context'] ?? '').toString(),
      journalistAngle: (json['journalistAngle'] ?? '').toString(),
      pressureLevel: _toInt(json['pressureLevel']),
    );
  }
}

class MediaSimulationQuestion {
  MediaSimulationQuestion({
    required this.id,
    required this.questionId,
    required this.question,
    required this.expectedElements,
    required this.difficulty,
  });

  final String id;
  final String questionId;
  final String question;
  final List<String> expectedElements;
  final int difficulty;

  factory MediaSimulationQuestion.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['questionId'] ?? '').toString();
    return MediaSimulationQuestion(
      id: id,
      questionId: (json['questionId'] ?? id).toString(),
      question: (json['question'] ?? '').toString(),
      expectedElements: _toStringList(json['expectedElements']),
      difficulty: _toInt(json['difficulty']),
    );
  }
}

class MediaTrainingSession {
  MediaTrainingSession({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.status,
    required this.instructions,
    required this.simulationQuestions,
    this.simulationCase,
  });

  final String id;
  final String lessonId;
  final String lessonTitle;
  final String status;
  final List<String> instructions;
  final List<MediaSimulationQuestion> simulationQuestions;
  final MediaSimulationCasePreview? simulationCase;

  factory MediaTrainingSession.fromJson(Map<String, dynamic> json) {
    final simulationCaseJson = json['simulationCase'];
    return MediaTrainingSession(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      lessonTitle: (json['lessonTitle'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      instructions: _toStringList(json['instructions']),
      simulationQuestions: _toList(json['simulationQuestions'])
          .map((item) => MediaSimulationQuestion.fromJson(item))
          .toList(),
      simulationCase: simulationCaseJson is Map<String, dynamic>
          ? MediaSimulationCasePreview.fromJson(simulationCaseJson)
          : null,
    );
  }
}

class MediaTrainingEvaluationResult {
  MediaTrainingEvaluationResult({
    required this.sessionId,
    required this.status,
    required this.progressPercent,
    required this.completedObjectives,
    required this.totalObjectives,
    required this.answers,
    required this.evaluation,
    this.unlockedNextLessonId,
    this.unlockedNextLessonTitle,
    this.completionStatus,
  });

  final String sessionId;
  final String status;
  final double progressPercent;
  final int completedObjectives;
  final int totalObjectives;
  final List<MediaTrainingScoredAnswer> answers;
  final MediaTrainingEvaluation evaluation;
  final String? unlockedNextLessonId;
  final String? unlockedNextLessonTitle;
  final String? completionStatus;

  factory MediaTrainingEvaluationResult.fromJson(Map<String, dynamic> json) {
    final lessonJourney =
        (json['lessonJourney'] as Map?)?.cast<String, dynamic>() ?? const {};
    return MediaTrainingEvaluationResult(
      sessionId: (json['sessionId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      progressPercent: _toDouble(json['progressPercent']) ?? 0,
      completedObjectives: _toInt(json['completedObjectives']),
      totalObjectives: _toInt(json['totalObjectives']),
      answers: _toList(json['answers'])
          .map((item) => MediaTrainingScoredAnswer.fromJson(item))
          .toList(),
      evaluation: MediaTrainingEvaluation.fromJson(
        (json['evaluation'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      unlockedNextLessonId: lessonJourney['unlockedNextLessonId']?.toString(),
      unlockedNextLessonTitle:
          lessonJourney['unlockedNextLessonTitle']?.toString(),
      completionStatus: lessonJourney['completionStatus']?.toString(),
    );
  }
}

class MediaTrainingScoredAnswer {
  MediaTrainingScoredAnswer({
    required this.questionId,
    required this.answer,
    required this.score,
    required this.feedback,
    required this.provider,
  });

  final String questionId;
  final String answer;
  final double score;
  final String feedback;
  final String provider;

  factory MediaTrainingScoredAnswer.fromJson(Map<String, dynamic> json) {
    return MediaTrainingScoredAnswer(
      questionId: (json['questionId'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      score: _toDouble(json['score']) ?? 0,
      feedback: (json['feedback'] ?? '').toString(),
      provider: (json['provider'] ?? 'HEURISTIC').toString(),
    );
  }
}

class MediaTrainingEvaluation {
  MediaTrainingEvaluation({
    required this.provider,
    required this.overallScore,
    required this.qaScore,
    required this.caseHandlingScore,
    required this.answerQualityScore,
    required this.readinessLevel,
    required this.lessonCompletionStatus,
    required this.coachSummary,
    required this.nextSessionFocus,
    required this.metrics,
    required this.strengths,
    required this.improvements,
    required this.rectifications,
    required this.suggestedDrills,
    required this.riskFlags,
    this.improvedAnswerExample,
    this.recommendedNextLessonId,
  });

  final String provider;
  final double overallScore;
  final double qaScore;
  final double caseHandlingScore;
  final double answerQualityScore;
  final String readinessLevel;
  final String lessonCompletionStatus;
  final String coachSummary;
  final String nextSessionFocus;
  final MediaTrainingMetrics metrics;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> rectifications;
  final List<String> suggestedDrills;
  final List<String> riskFlags;
  final String? improvedAnswerExample;
  final String? recommendedNextLessonId;

  factory MediaTrainingEvaluation.fromJson(Map<String, dynamic> json) {
    return MediaTrainingEvaluation(
      provider: (json['provider'] ?? 'HEURISTIC').toString(),
      overallScore: _toDouble(json['overallScore']) ?? 0,
      qaScore: _toDouble(json['qaScore']) ?? 0,
      caseHandlingScore: _toDouble(json['caseHandlingScore']) ?? 0,
      answerQualityScore: _toDouble(json['answerQualityScore']) ?? 0,
      readinessLevel: (json['readinessLevel'] ?? '').toString(),
      lessonCompletionStatus: (json['lessonCompletionStatus'] ?? '').toString(),
      coachSummary: (json['coachSummary'] ?? '').toString(),
      nextSessionFocus: (json['nextSessionFocus'] ?? '').toString(),
      metrics: MediaTrainingMetrics.fromJson(
        (json['metrics'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      strengths: _toStringList(json['strengths']),
      improvements: _toStringList(json['improvements']),
      rectifications: _toStringList(json['rectifications']),
      suggestedDrills: _toStringList(json['suggestedDrills']),
      riskFlags: _toStringList(json['riskFlags']),
      improvedAnswerExample: json['improvedAnswerExample']?.toString(),
      recommendedNextLessonId: json['recommendedNextLessonId']?.toString(),
    );
  }
}

class MediaTrainingMetrics {
  MediaTrainingMetrics({
    required this.clarity,
    required this.messageControl,
    required this.emotionalControl,
    required this.discipline,
    required this.structure,
    required this.pressureManagement,
  });

  final double clarity;
  final double messageControl;
  final double emotionalControl;
  final double discipline;
  final double structure;
  final double pressureManagement;

  factory MediaTrainingMetrics.fromJson(Map<String, dynamic> json) {
    return MediaTrainingMetrics(
      clarity: _toDouble(json['clarity']) ?? 0,
      messageControl: _toDouble(json['messageControl']) ?? 0,
      emotionalControl: _toDouble(json['emotionalControl']) ?? 0,
      discipline: _toDouble(json['discipline']) ?? 0,
      structure: _toDouble(json['structure']) ?? 0,
      pressureManagement: _toDouble(json['pressureManagement']) ?? 0,
    );
  }
}

class MediaTrainingSessionSummary {
  MediaTrainingSessionSummary({
    required this.id,
    required this.lessonTitle,
    required this.status,
    this.overallScore,
    this.readinessLevel,
    this.createdAt,
  });

  final String id;
  final String lessonTitle;
  final String status;
  final double? overallScore;
  final String? readinessLevel;
  final DateTime? createdAt;

  factory MediaTrainingSessionSummary.fromJson(Map<String, dynamic> json) {
    return MediaTrainingSessionSummary(
      id: (json['id'] ?? '').toString(),
      lessonTitle: (json['lessonTitle'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      overallScore: _toDouble(json['overallScore']),
      readinessLevel: json['readinessLevel']?.toString(),
      createdAt: _toDate(json['createdAt']),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<Map<String, dynamic>> _toList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
  return const [];
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
