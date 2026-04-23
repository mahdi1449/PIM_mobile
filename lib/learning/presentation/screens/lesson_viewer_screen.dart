import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_config.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_course.dart';
import '../../data/models/learning_lesson.dart';
import '../../theme/learning_colors.dart';
import 'quiz_screen.dart';
import '../utils/lesson_content_parser.dart';
import '../widgets/lesson_block_card.dart';
import '../widgets/vocabulary_cards.dart';
import 'lesson_practice_screen.dart';
import '../widgets/learning_top_bar.dart';
import 'lesson_tasks_screen.dart';

class LessonViewerScreen extends StatefulWidget {
  const LessonViewerScreen({
    super.key,
    required this.playerId,
    required this.course,
    required this.lesson,
  });

  final String playerId;
  final LearningCourse course;
  final LearningLesson lesson;

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  final LearningApi _api = LearningApi();
  bool _saving = false;
  late final List<LessonSection> _sections;
  late final List<VocabularyPair> _vocabulary;
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _sections = LessonContentParser.parse(widget.lesson.content);
    _vocabulary = _sections.expand((s) => s.vocabulary).toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _sections.length;
    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: LearningTopBar(
        title: 'ODIN',
        avatarLetter: widget.playerId.isNotEmpty ? widget.playerId[0] : 'O',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: LearningColors.navy,
            ),
            child: Stack(
              children: [
                if (widget.lesson.imageUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: PageView.builder(
                      itemCount: widget.lesson.imageUrls.length,
                      itemBuilder: (context, index) {
                        final url = widget.lesson.imageUrls[index];
                        return CachedNetworkImage(
                          imageUrl: url.startsWith('http')
                              ? url
                              : '${_apiBase()}$url',
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: LearningColors.navy2),
                          errorWidget: (_, __, ___) =>
                              Container(color: LearningColors.navy2),
                        );
                      },
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: LearningColors.lime.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: LearningColors.lime),
                    ),
                    child: Text(
                      'LESSON ${widget.lesson.order}',
                      style: TextStyle(
                        color: LearningColors.lime,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LearningColors.lime,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 42,
                      color: LearningColors.text,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    widget.lesson.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pageCount == 0 ? 0 : (_pageIndex + 1) / pageCount,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE9EDF3),
                    valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_pageIndex + 1}/$pageCount',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: LearningColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 420,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              itemCount: _sections.length,
              itemBuilder: (context, i) {
                final section = _sections[i];
                final blocks = section.blocks
                    .where((b) => b.type != LessonBlockType.vocabulary)
                    .toList();
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: i == _pageIndex ? 0 : 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: LessonBlockCard(
                        title: section.title,
                        blocks: blocks,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_vocabulary.isNotEmpty) VocabularyCards(pairs: _vocabulary),
          const SizedBox(height: 18),
          if (widget.lesson.taskCount > 0)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: LearningColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonTasksScreen(
                        playerId: widget.playerId,
                        courseId: widget.course.id,
                        lesson: widget.lesson,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Practice Tasks • ${widget.lesson.taskCount}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (widget.lesson.taskCount > 0) const SizedBox(height: 10),
          if (widget.lesson.quizCount > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LearningColors.lime,
                  foregroundColor: LearningColors.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final passed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        playerId: widget.playerId,
                        courseId: widget.course.id,
                        lesson: widget.lesson,
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  if (passed == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quiz passed. Progress updated.'),
                      ),
                    );
                  }
                },
                child: Text(
                  'Start Quiz • ${widget.lesson.quizCount} questions',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (_vocabulary.length >= 4) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: LearningColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonPracticeScreen(pairs: _vocabulary),
                    ),
                  );
                },
                child: const Text(
                  'Practice Vocabulary (Animated)',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: LearningColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _pageIndex <= 0
                      ? null
                      : () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        ),
                  child: const Text(
                    'Previous',
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _pageIndex >= pageCount - 1
                      ? null
                      : () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        ),
                  child: const Text(
                    'Next',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: LearningColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await _api.updateProgress(
                          playerId: widget.playerId,
                          courseId: widget.course.id,
                          lessonId: widget.lesson.id,
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(
                _saving ? 'Saving…' : 'Mark lesson as completed',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _apiBase() {
    return AppConfig.baseUrl;
  }
}
