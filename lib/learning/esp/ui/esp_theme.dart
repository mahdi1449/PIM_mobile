import 'package:flutter/material.dart';
import '../models/esp_models.dart';

class EspTheme {
  EspTheme._();

  static const Color background = Color(0xFF050B14);
  static const Color surface = Color(0xFF0E1828);
  static const Color surfaceAlt = Color(0xFF132036);
  static const Color border = Color(0xFF1F3352);
  static const Color textPrimary = Color(0xFFE6F1FF);
  static const Color textSecondary = Color(0xFF9BB2CD);
  static const Color neonBlue = Color(0xFF38BDF8);
  static const Color neonGreen = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceAlt],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonBlue, neonGreen],
  );
}

String lessonTypeLabel(EspLessonType type) {
  switch (type) {
    case EspLessonType.vocabulary:
      return 'Vocabulary';
    case EspLessonType.listening:
      return 'Listening';
    case EspLessonType.speaking:
      return 'Speaking';
    case EspLessonType.quiz:
      return 'Quiz';
    case EspLessonType.reading:
      return 'Reading';
    case EspLessonType.writing:
      return 'Writing';
  }
}

IconData lessonTypeIcon(EspLessonType type) {
  switch (type) {
    case EspLessonType.vocabulary:
      return Icons.menu_book_rounded;
    case EspLessonType.listening:
      return Icons.hearing_rounded;
    case EspLessonType.speaking:
      return Icons.mic_rounded;
    case EspLessonType.quiz:
      return Icons.quiz_rounded;
    case EspLessonType.reading:
      return Icons.chrome_reader_mode_outlined;
    case EspLessonType.writing:
      return Icons.edit_note_rounded;
  }
}

String difficultyLabel(EspDifficulty value) {
  switch (value) {
    case EspDifficulty.beginner:
      return 'Beginner';
    case EspDifficulty.intermediate:
      return 'Intermediate';
    case EspDifficulty.pro:
      return 'Pro';
  }
}

Color difficultyColor(EspDifficulty value) {
  switch (value) {
    case EspDifficulty.beginner:
      return EspTheme.neonGreen;
    case EspDifficulty.intermediate:
      return EspTheme.neonBlue;
    case EspDifficulty.pro:
      return EspTheme.warning;
  }
}

String exerciseTypeLabel(EspExerciseType type) {
  switch (type) {
    case EspExerciseType.fillBlank:
      return 'Fill in the blanks';
    case EspExerciseType.matching:
      return 'Matching';
    case EspExerciseType.dragDrop:
      return 'Drag & drop';
    case EspExerciseType.speaking:
      return 'Speaking';
  }
}
