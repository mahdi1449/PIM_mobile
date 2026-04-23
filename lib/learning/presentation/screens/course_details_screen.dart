import 'package:flutter/material.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_course.dart';
import '../../data/models/learning_lesson.dart';
import '../../theme/learning_colors.dart';
import 'lesson_viewer_screen.dart';
import '../widgets/learning_top_bar.dart';
import 'quiz_screen.dart';
import 'lesson_tasks_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({
    super.key,
    required this.playerId,
    required this.course,
  });

  final String playerId;
  final LearningCourse course;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final LearningApi _api = LearningApi();
  String? _expandedLessonId;

  Future<Map<String, dynamic>> _load() =>
      _api.courseLessons(widget.course.id, playerId: widget.playerId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _load(),
      builder: (context, snapshot) {
        final lessons =
            (snapshot.data?['lessons'] as List<LearningLesson>?) ?? const [];
        final done = lessons.where((l) => l.completed).length;
        final total = lessons.length;
        final progress = total == 0 ? 0.0 : done / total;
        if (_expandedLessonId == null && lessons.isNotEmpty) {
          _expandedLessonId = lessons
              .firstWhere((l) => !l.completed, orElse: () => lessons.first)
              .id;
        }

        return Scaffold(
          backgroundColor: LearningColors.surface,
          appBar: LearningTopBar(
            title: 'ODIN',
            avatarLetter: (widget.playerId.isNotEmpty
                ? widget.playerId[0]
                : 'O'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: LearningColors.navy2,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      bottom: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: LearningColors.lime,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.course.level.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.course.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LearningColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: LearningColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.description,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'COURSE\nPROGRESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: LearningColors.textMuted,
                          ),
                        ),
                        Text(
                          '$done/$total Lessons\nCompleted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: LearningColors.limeDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE9EDF3),
                        valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Curriculum',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (snapshot.hasError)
                Text(
                  'Failed to load lessons: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              for (final lesson in lessons) ...[
                _lessonTile(lesson),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _lessonTile(LearningLesson lesson) {
    final isCurrent = !lesson.completed;
    final expanded = _expandedLessonId == lesson.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isCurrent
            ? LearningColors.lime.withValues(alpha: 0.10)
            : LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: expanded || isCurrent
              ? LearningColors.lime
              : LearningColors.border,
          width: expanded || isCurrent ? 1.2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonViewerScreen(
                playerId: widget.playerId,
                course: widget.course,
                lesson: lesson,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lesson.completed
                          ? LearningColors.lime
                          : const Color(0xFFE9EDF3),
                    ),
                    child: Icon(
                      lesson.completed
                          ? Icons.check_rounded
                          : Icons.play_arrow_rounded,
                      color: lesson.completed
                          ? LearningColors.text
                          : LearningColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LESSON ${lesson.order}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: LearningColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _miniPill('${lesson.quizCount} Quiz'),
                            const SizedBox(width: 8),
                            _miniPill('${lesson.taskCount} Tasks'),
                            const SizedBox(width: 8),
                            if (lesson.suggestedForInjuryCommunication)
                              _miniPill(
                                'Injury comms',
                                icon: Icons.health_and_safety_outlined,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(
                      () => _expandedLessonId = expanded ? null : lesson.id,
                    ),
                    icon: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: LearningColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: LearningColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LessonViewerScreen(
                                  playerId: widget.playerId,
                                  course: widget.course,
                                  lesson: lesson,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Open Lesson',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LearningColors.lime,
                            foregroundColor: LearningColors.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed:
                              lesson.taskCount <= 0 && lesson.quizCount <= 0
                              ? null
                              : () {
                                  if (lesson.taskCount > 0) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LessonTasksScreen(
                                          playerId: widget.playerId,
                                          courseId: widget.course.id,
                                          lesson: lesson,
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QuizScreen(
                                        playerId: widget.playerId,
                                        courseId: widget.course.id,
                                        lesson: lesson,
                                      ),
                                    ),
                                  );
                                },
                          child: Text(
                            lesson.taskCount > 0
                                ? 'Practice'
                                : (lesson.quizCount > 0
                                      ? 'Start Quiz'
                                      : 'No Practice'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPill(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: LearningColors.textMuted),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: LearningColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
