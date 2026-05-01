import 'package:flutter/material.dart';
import '../models/esp_models.dart';

class EspMockData {
  EspMockData._();

  static const EspPlayerProgress playerProgress = EspPlayerProgress(
    levelName: 'Intermediate',
    completionPercent: 0.68,
    dailyStreak: 9,
    xp: 1240,
    completedLessons: 17,
    totalLessons: 25,
    avgQuizScore: 84,
  );

  static const List<EspLesson> lessons = [
    EspLesson(
      id: 'l1',
      title: 'Football Vocabulary Basics',
      type: EspLessonType.vocabulary,
      durationMinutes: 18,
      difficulty: EspDifficulty.beginner,
      progress: 1,
      recommended: true,
      description:
          'Core football terms for match actions, positions, and common coach instructions.',
      vocabulary: [
        EspVocabularyItem(
          term: 'Tackle',
          definition: 'To stop an opponent and take the ball.',
          example: 'The defender made a clean tackle in the box.',
          icon: Icons.shield_outlined,
        ),
        EspVocabularyItem(
          term: 'Cross',
          definition: 'A pass sent from the side into the center.',
          example: 'The winger delivered a perfect cross.',
          icon: Icons.swap_horiz_rounded,
        ),
        EspVocabularyItem(
          term: 'Equaliser',
          definition: 'A goal that makes the score level.',
          example: 'He scored the equaliser in minute 88.',
          icon: Icons.sports_score_outlined,
        ),
      ],
      scenarios: [
        'Pre-match team talk',
        'In-game tactical instruction',
        'Post-match short interview',
      ],
    ),
    EspLesson(
      id: 'l2',
      title: 'Training Communication',
      type: EspLessonType.listening,
      durationMinutes: 22,
      difficulty: EspDifficulty.beginner,
      progress: 0.55,
      description:
          'Understand coach commands during warm-up, drills, and tactical transitions.',
      vocabulary: [
        EspVocabularyItem(
          term: 'Warm up',
          definition: 'Prepare your body before intense exercise.',
          example: 'We always warm up for ten minutes.',
          icon: Icons.local_fire_department_outlined,
        ),
        EspVocabularyItem(
          term: 'Drill',
          definition: 'A repeated exercise focused on one skill.',
          example: 'The coach set a passing drill in groups.',
          icon: Icons.sports_soccer_rounded,
        ),
      ],
      scenarios: [
        'Coach giving drill instructions',
        'Player asking for clarification',
      ],
    ),
    EspLesson(
      id: 'l3',
      title: 'Match Commentary',
      type: EspLessonType.reading,
      durationMinutes: 16,
      difficulty: EspDifficulty.intermediate,
      progress: 0.3,
      description:
          'Read football narratives and identify key events, tempo, and momentum shifts.',
      vocabulary: [
        EspVocabularyItem(
          term: 'Possession',
          definition: 'Control of the ball by a team.',
          example: 'They kept 64% possession in the first half.',
          icon: Icons.pie_chart_outline_rounded,
        ),
      ],
      scenarios: [
        'Match recap article',
        'Live minute-by-minute report',
      ],
    ),
    EspLesson(
      id: 'l4',
      title: 'Press Conference Essentials',
      type: EspLessonType.speaking,
      durationMinutes: 20,
      difficulty: EspDifficulty.intermediate,
      progress: 0.1,
      description:
          'Practice short, clear answers for media in pre- and post-match interviews.',
      vocabulary: [
        EspVocabularyItem(
          term: 'Performance',
          definition: 'How well a team or player played.',
          example: 'Our performance improved after half-time.',
          icon: Icons.trending_up_outlined,
        ),
      ],
      scenarios: [
        'Coach interview simulation',
        'Player mixed-zone response',
      ],
    ),
    EspLesson(
      id: 'l5',
      title: 'Fitness & Recovery Language',
      type: EspLessonType.writing,
      durationMinutes: 19,
      difficulty: EspDifficulty.intermediate,
      progress: 0,
      description:
          'Communicate injury symptoms, recovery plans, and load management with staff.',
      vocabulary: [
        EspVocabularyItem(
          term: 'Cool down',
          definition: 'Low intensity movement after training.',
          example: 'We cool down before leaving the field.',
          icon: Icons.spa_outlined,
        ),
        EspVocabularyItem(
          term: 'Hydration',
          definition: 'Keeping enough fluid in your body.',
          example: 'Hydration is key after high-intensity sessions.',
          icon: Icons.water_drop_outlined,
        ),
      ],
      scenarios: [
        'Doctor-player conversation',
        'Physio rehabilitation instructions',
      ],
    ),
    EspLesson(
      id: 'l6',
      title: 'Sports English Quick Check',
      type: EspLessonType.quiz,
      durationMinutes: 8,
      difficulty: EspDifficulty.pro,
      progress: 0,
      description: 'Short adaptive quiz to validate your week progress.',
      vocabulary: [
        EspVocabularyItem(
          term: 'Set piece',
          definition: 'A planned restart like a corner or free kick.',
          example: 'We scored from a set piece.',
          icon: Icons.flag_outlined,
        ),
      ],
      scenarios: ['Weekly checkpoint'],
    ),
  ];

  static const List<EspExercise> exercises = [
    EspExercise(
      id: 'e1',
      title: 'Fill the Blank: Coach Commands',
      type: EspExerciseType.fillBlank,
      instructions: 'Complete the phrase: "Keep your ____ up and stay compact."',
      xpReward: 20,
    ),
    EspExercise(
      id: 'e2',
      title: 'Match Words to Actions',
      type: EspExerciseType.matching,
      instructions: 'Match "cross, tackle, save, score" to the right image.',
      xpReward: 25,
    ),
    EspExercise(
      id: 'e3',
      title: 'Drag & Drop Lineup Calls',
      type: EspExerciseType.dragDrop,
      instructions: 'Place tactical instructions in the correct press conference flow.',
      xpReward: 30,
    ),
    EspExercise(
      id: 'e4',
      title: 'Speaking Drill',
      type: EspExerciseType.speaking,
      instructions: 'Read a short post-match statement with clear pronunciation.',
      xpReward: 35,
    ),
  ];

  static const List<EspQuizQuestion> quizQuestions = [
    EspQuizQuestion(
      id: 'q1',
      type: EspQuestionType.mcq,
      question: 'Which sentence is correct in football English?',
      options: [
        'The referee shoot the match.',
        'The striker scored an equaliser.',
        'The goalkeeper dribbled the stadium.',
      ],
      correctIndex: 1,
      explanation:
          '"Scored an equaliser" is the correct football expression when a team levels the score.',
    ),
    EspQuizQuestion(
      id: 'q2',
      type: EspQuestionType.trueFalse,
      question: 'True or False: A warm-up helps prevent injuries.',
      options: ['True', 'False'],
      correctIndex: 0,
      explanation:
          'True. Warm-up prepares muscles and joints before high-intensity effort.',
    ),
    EspQuizQuestion(
      id: 'q3',
      type: EspQuestionType.listening,
      question:
          'Listening check: Coach says "Drop deeper and hold the line." What is the main instruction?',
      options: [
        'Move up and press high',
        'Defend lower and stay organized',
        'Switch to attack only',
      ],
      correctIndex: 1,
      explanation:
          'The instruction asks defenders to stay deeper and keep a coordinated defensive line.',
    ),
  ];

  static const List<EspBadge> badges = [
    EspBadge(
      title: 'Fast Learner',
      description: 'Complete 5 lessons in one week.',
      icon: Icons.bolt_rounded,
      unlocked: true,
    ),
    EspBadge(
      title: 'Top Player',
      description: 'Reach top 3 in team leaderboard.',
      icon: Icons.emoji_events_rounded,
      unlocked: true,
    ),
    EspBadge(
      title: 'Voice Master',
      description: 'Score 90% in speaking drills.',
      icon: Icons.mic_rounded,
      unlocked: false,
    ),
  ];

  static const List<EspLeaderboardEntry> leaderboard = [
    EspLeaderboardEntry(rank: 1, name: 'Lina B.', team: 'U19', xp: 1450),
    EspLeaderboardEntry(rank: 2, name: 'Youssef A.', team: 'U19', xp: 1390),
    EspLeaderboardEntry(rank: 3, name: 'Adam K.', team: 'U17', xp: 1310),
    EspLeaderboardEntry(rank: 4, name: 'Sami H.', team: 'U17', xp: 1260),
  ];

  static const List<EspTeacherMetric> teacherMetrics = [
    EspTeacherMetric(
      label: 'Total Players',
      value: '124',
      deltaLabel: '+8 this month',
      positive: true,
    ),
    EspTeacherMetric(
      label: 'Active Learners',
      value: '89',
      deltaLabel: '+11% weekly',
      positive: true,
    ),
    EspTeacherMetric(
      label: 'Lessons Created',
      value: '42',
      deltaLabel: '+4 new',
      positive: true,
    ),
    EspTeacherMetric(
      label: 'Completion Rate',
      value: '76%',
      deltaLabel: '-2% this week',
      positive: false,
    ),
  ];

  static const List<EspPlayerPerformance> playerPerformances = [
    EspPlayerPerformance(
      name: 'Lina B.',
      progressPercent: 91,
      vocabularyScore: 94,
      listeningScore: 88,
      speakingScore: 86,
    ),
    EspPlayerPerformance(
      name: 'Youssef A.',
      progressPercent: 83,
      vocabularyScore: 87,
      listeningScore: 78,
      speakingScore: 82,
    ),
    EspPlayerPerformance(
      name: 'Adam K.',
      progressPercent: 69,
      vocabularyScore: 74,
      listeningScore: 66,
      speakingScore: 61,
    ),
  ];

  static final List<EspWeakArea> weakAreas = [
    const EspWeakArea(
      label: 'Listening',
      value: 58,
      color: Color(0xFF22D3EE),
    ),
    const EspWeakArea(
      label: 'Medical Vocabulary',
      value: 47,
      color: Color(0xFF60A5FA),
    ),
    const EspWeakArea(
      label: 'Press Conference Fluency',
      value: 42,
      color: Color(0xFF34D399),
    ),
  ];

  static const List<EspContentBlockType> contentBlocks = [
    EspContentBlockType(label: 'Text', icon: Icons.short_text_rounded),
    EspContentBlockType(label: 'Video', icon: Icons.play_circle_outline_rounded),
    EspContentBlockType(label: 'Audio', icon: Icons.headset_mic_outlined),
    EspContentBlockType(label: 'Vocabulary', icon: Icons.menu_book_rounded),
  ];
}
