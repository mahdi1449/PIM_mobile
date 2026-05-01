import 'package:flutter/material.dart';

enum EspLessonType {
  vocabulary,
  listening,
  speaking,
  quiz,
  reading,
  writing,
}

enum EspDifficulty { beginner, intermediate, pro }

enum EspExerciseType { fillBlank, matching, dragDrop, speaking }

enum EspQuestionType { mcq, trueFalse, listening }

class EspVocabularyItem {
  const EspVocabularyItem({
    required this.term,
    required this.definition,
    required this.example,
    required this.icon,
  });

  final String term;
  final String definition;
  final String example;
  final IconData icon;
}

class EspLesson {
  const EspLesson({
    required this.id,
    required this.title,
    required this.type,
    required this.durationMinutes,
    required this.difficulty,
    required this.progress,
    required this.description,
    required this.vocabulary,
    required this.scenarios,
    this.recommended = false,
  });

  final String id;
  final String title;
  final EspLessonType type;
  final int durationMinutes;
  final EspDifficulty difficulty;
  final double progress;
  final String description;
  final List<EspVocabularyItem> vocabulary;
  final List<String> scenarios;
  final bool recommended;
}

class EspExercise {
  const EspExercise({
    required this.id,
    required this.title,
    required this.type,
    required this.instructions,
    required this.xpReward,
  });

  final String id;
  final String title;
  final EspExerciseType type;
  final String instructions;
  final int xpReward;
}

class EspQuizQuestion {
  const EspQuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;
  final EspQuestionType type;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class EspBadge {
  const EspBadge({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}

class EspLeaderboardEntry {
  const EspLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.team,
    required this.xp,
  });

  final int rank;
  final String name;
  final String team;
  final int xp;
}

class EspPlayerProgress {
  const EspPlayerProgress({
    required this.levelName,
    required this.completionPercent,
    required this.dailyStreak,
    required this.xp,
    required this.completedLessons,
    required this.totalLessons,
    required this.avgQuizScore,
  });

  final String levelName;
  final double completionPercent;
  final int dailyStreak;
  final int xp;
  final int completedLessons;
  final int totalLessons;
  final int avgQuizScore;
}

class EspTeacherMetric {
  const EspTeacherMetric({
    required this.label,
    required this.value,
    required this.deltaLabel,
    required this.positive,
  });

  final String label;
  final String value;
  final String deltaLabel;
  final bool positive;
}

class EspPlayerPerformance {
  const EspPlayerPerformance({
    required this.name,
    required this.progressPercent,
    required this.vocabularyScore,
    required this.listeningScore,
    required this.speakingScore,
  });

  final String name;
  final int progressPercent;
  final int vocabularyScore;
  final int listeningScore;
  final int speakingScore;
}

class EspWeakArea {
  const EspWeakArea({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class EspContentBlockType {
  const EspContentBlockType({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
