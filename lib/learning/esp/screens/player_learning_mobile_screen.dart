import 'package:flutter/material.dart';
import '../data/esp_mock_data.dart';
import '../models/esp_models.dart';
import '../ui/esp_theme.dart';

class PlayerLearningMobileScreen extends StatefulWidget {
  const PlayerLearningMobileScreen({
    super.key,
    required this.playerName,
    this.avatarUrl,
  });

  final String playerName;
  final String? avatarUrl;

  @override
  State<PlayerLearningMobileScreen> createState() =>
      _PlayerLearningMobileScreenState();
}

class _PlayerLearningMobileScreenState
    extends State<PlayerLearningMobileScreen> {
  final Map<String, int> _selectedAnswers = <String, int>{};

  EspLesson get _recommendedLesson =>
      EspMockData.lessons.firstWhere((lesson) => lesson.recommended);

  @override
  Widget build(BuildContext context) {
    final progress = EspMockData.playerProgress;
    final mediaQuery = MediaQuery.of(context);
    final currentScale = mediaQuery.textScaler.scale(1.0);
    final clampedScale = currentScale.clamp(0.95, 1.15).toDouble();

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(clampedScale)),
      child: Scaffold(
        backgroundColor: EspTheme.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeaderCard(
                playerName: widget.playerName,
                avatarUrl: widget.avatarUrl,
                levelName: progress.levelName,
                dailyStreak: progress.dailyStreak,
              ),
              const SizedBox(height: 14),
              _ProgressCard(progress: progress),
              const SizedBox(height: 14),
              _RecommendedLessonCard(
                lesson: _recommendedLesson,
                onStart: () => _openLessonDetail(_recommendedLesson),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.menu_book_rounded,
                title: 'Lessons',
                subtitle:
                    'Vocabulary, listening, speaking, and match scenarios',
              ),
              const SizedBox(height: 10),
              ...EspMockData.lessons.map(
                (lesson) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LessonCard(
                    lesson: lesson,
                    onTap: () => _openLessonDetail(lesson),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                icon: Icons.fitness_center_rounded,
                title: 'Tasks / Exercises',
                subtitle:
                    'Interactive practice: fill, match, drag, and speaking',
              ),
              const SizedBox(height: 10),
              ...EspMockData.exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExerciseCard(exercise: exercise),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                icon: Icons.quiz_rounded,
                title: 'Quiz System',
                subtitle: 'MCQ, True/False, Listening and instant feedback',
              ),
              const SizedBox(height: 10),
              ...EspMockData.quizQuestions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _QuizCard(
                    question: question,
                    selectedIndex: _selectedAnswers[question.id],
                    onSelect: (index) {
                      setState(() {
                        _selectedAnswers[question.id] = index;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                icon: Icons.insights_rounded,
                title: 'Progress Tracking',
                subtitle:
                    '${progress.completedLessons}/${progress.totalLessons} lessons completed',
              ),
              const SizedBox(height: 10),
              _StatsGrid(progress: progress),
              const SizedBox(height: 18),
              const _SectionTitle(
                icon: Icons.emoji_events_rounded,
                title: 'Gamification',
                subtitle: 'Badges, streak, and team leaderboard',
              ),
              const SizedBox(height: 10),
              _BadgeStrip(badges: EspMockData.badges),
              const SizedBox(height: 10),
              _LeaderboardCard(entries: EspMockData.leaderboard),
              const SizedBox(height: 18),
              const _SectionTitle(
                icon: Icons.smart_toy_rounded,
                title: 'AI Assistant',
                subtitle:
                    'Chatbot practice, voice interaction, and personalized recommendations',
              ),
              const SizedBox(height: 10),
              const _AiToolsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLessonDetail(EspLesson lesson) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: EspTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: EspTheme.border)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EspTheme.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: EspTheme.accentGradient,
                    ),
                    child: Icon(
                      lessonTypeIcon(lesson.type),
                      color: EspTheme.background,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            color: EspTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${lessonTypeLabel(lesson.type)} • ${lesson.durationMinutes} min • ${difficultyLabel(lesson.difficulty)}',
                          style: const TextStyle(
                            color: EspTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: EspTheme.surfaceAlt,
                  border: Border.all(color: EspTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: EspTheme.neonBlue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Video / Audio lesson player placeholder',
                        style: TextStyle(
                          color: EspTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lesson.description,
                style: const TextStyle(
                  color: EspTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Vocabulary',
                style: TextStyle(
                  color: EspTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...lesson.vocabulary.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EspTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EspTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: EspTheme.neonGreen, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.term,
                                style: const TextStyle(
                                  color: EspTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.definition,
                                style: const TextStyle(
                                  color: EspTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.example,
                                style: TextStyle(
                                  color: EspTheme.neonBlue.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Real-world scenarios',
                style: TextStyle(
                  color: EspTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...lesson.scenarios.map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: EspTheme.neonBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scenario,
                          style: const TextStyle(color: EspTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.mic_rounded),
                      label: const Text('Speaking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EspTheme.neonBlue,
                        side: const BorderSide(color: EspTheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Practice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EspTheme.neonGreen,
                        foregroundColor: EspTheme.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.playerName,
    required this.avatarUrl,
    required this.levelName,
    required this.dailyStreak,
  });

  final String playerName;
  final String? avatarUrl;
  final String levelName;
  final int dailyStreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: EspTheme.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EspTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: EspTheme.surfaceAlt,
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: EspTheme.textPrimary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $playerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EspTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$levelName • English for Sportive Purposes',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EspTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: EspTheme.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: EspTheme.neonGreen.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(
                  '$dailyStreak',
                  style: const TextStyle(
                    color: EspTheme.neonGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final EspPlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EspTheme.border),
        color: EspTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: EspTheme.neonBlue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Learning Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EspTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress.completionPercent * 100).round()}%',
                style: const TextStyle(
                  color: EspTheme.neonGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.completionPercent),
            duration: const Duration(milliseconds: 900),
            builder: (_, value, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: EspTheme.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    EspTheme.neonBlue,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.completedLessons}/${progress.totalLessons} lessons complete • ${progress.xp} XP',
            style: const TextStyle(color: EspTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RecommendedLessonCard extends StatelessWidget {
  const _RecommendedLessonCard({required this.lesson, required this.onStart});

  final EspLesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: EspTheme.accentGradient,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: EspTheme.background,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended lesson',
                  style: TextStyle(
                    color: EspTheme.background,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EspTheme.background),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: EspTheme.background,
              foregroundColor: EspTheme.neonBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: EspTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: EspTheme.border),
          ),
          child: Icon(icon, size: 17, color: EspTheme.neonBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EspTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EspTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final EspLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difficulty = difficultyLabel(lesson.difficulty);
    final difficultyColorValue = difficultyColor(lesson.difficulty);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EspTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EspTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    lessonTypeIcon(lesson.type),
                    color: EspTheme.neonBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EspTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (lesson.recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EspTheme.neonGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          color: EspTheme.neonGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _MiniPill(
                    text: lessonTypeLabel(lesson.type),
                    color: EspTheme.neonBlue,
                  ),
                  _MiniPill(
                    text: '${lesson.durationMinutes} min',
                    color: EspTheme.textSecondary,
                  ),
                  _MiniPill(text: difficulty, color: difficultyColorValue),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: lesson.progress,
                  minHeight: 7,
                  backgroundColor: EspTheme.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    EspTheme.neonGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final EspExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EspTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: EspTheme.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.title,
                  style: const TextStyle(
                    color: EspTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MiniPill(
                text: '+${exercise.xpReward} XP',
                color: EspTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            exerciseTypeLabel(exercise.type),
            style: const TextStyle(
              color: EspTheme.neonBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.instructions,
            style: const TextStyle(color: EspTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
  });

  final EspQuizQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final answered = selectedIndex != null;
    final isCorrect = answered && selectedIndex == question.correctIndex;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: answered
              ? (isCorrect ? EspTheme.neonGreen : EspTheme.warning)
              : EspTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              color: EspTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(question.options.length, (index) {
            final option = question.options[index];
            final selected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? EspTheme.surfaceAlt
                          : EspTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? EspTheme.neonBlue : EspTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            color: EspTheme.neonBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: EspTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (answered) ...[
            const SizedBox(height: 6),
            Text(
              isCorrect ? 'Correct answer ✅' : 'Try again 👀',
              style: TextStyle(
                color: isCorrect ? EspTheme.neonGreen : EspTheme.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              question.explanation,
              style: const TextStyle(
                color: EspTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.progress});

  final EspPlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String>>[
      {'label': 'XP', 'value': '${progress.xp}'},
      {'label': 'Avg Quiz', 'value': '${progress.avgQuizScore}%'},
      {'label': 'Completed', 'value': '${progress.completedLessons}'},
      {'label': 'Streak', 'value': '${progress.dailyStreak}d'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EspTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EspTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['value']!,
                style: const TextStyle(
                  color: EspTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item['label']!,
                style: const TextStyle(color: EspTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.badges});

  final List<EspBadge> badges;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final badge = badges[index];
          return Container(
            width: 168,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: EspTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: badge.unlocked
                    ? EspTheme.neonGreen.withValues(alpha: 0.7)
                    : EspTheme.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      badge.icon,
                      color: badge.unlocked
                          ? EspTheme.warning
                          : EspTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        badge.title,
                        style: const TextStyle(
                          color: EspTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: const TextStyle(
                    color: EspTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: badges.length,
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries});

  final List<EspLeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EspTheme.border),
      ),
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '#${entry.rank}',
                        style: const TextStyle(
                          color: EspTheme.neonBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.name} • ${entry.team}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: EspTheme.textPrimary),
                      ),
                    ),
                    Text(
                      '${entry.xp} XP',
                      style: const TextStyle(
                        color: EspTheme.neonGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AiToolsCard extends StatelessWidget {
  const _AiToolsCard();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        'AI Chatbot Assistant',
        'Practice match communication with instant corrections',
        Icons.smart_toy_outlined,
      ),
      (
        'Voice Interaction',
        'Speech-to-text speaking drills for pronunciation',
        Icons.keyboard_voice_outlined,
      ),
      (
        'Personalized Recommendations',
        'Adaptive lesson suggestions by weak area',
        Icons.auto_awesome_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EspTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EspTheme.border),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EspTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EspTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$3, color: EspTheme.neonBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EspTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.$2,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EspTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
