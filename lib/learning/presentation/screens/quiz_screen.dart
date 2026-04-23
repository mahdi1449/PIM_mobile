import 'package:flutter/material.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_lesson.dart';
import '../../data/models/learning_quiz.dart';
import '../../theme/learning_colors.dart';
import '../widgets/learning_top_bar.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.playerId,
    required this.courseId,
    required this.lesson,
  });

  final String playerId;
  final String courseId;
  final LearningLesson lesson;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final LearningApi _api = LearningApi();
  late Future<List<LearningQuizQuestion>> _future;
  final Map<String, String> _answers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _api.lessonQuizzes(widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: LearningTopBar(
        title: 'Quiz',
        avatarLetter: widget.playerId.isNotEmpty ? widget.playerId[0] : 'O',
      ),
      body: FutureBuilder<List<LearningQuizQuestion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load quiz: ${snapshot.error}'),
            );
          }
          final questions = snapshot.data ?? const <LearningQuizQuestion>[];
          if (questions.isEmpty) {
            return const Center(child: Text('No questions for this lesson.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              Text(
                widget.lesson.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Answer all questions to unlock completion.',
                style: TextStyle(color: LearningColors.textMuted),
              ),
              const SizedBox(height: 16),
              for (final q in questions) ...[
                _questionCard(q),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 6),
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
                  onPressed: _submitting
                      ? null
                      : () async {
                          if (_answers.length != questions.length) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please answer all questions.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _submitting = true);
                          try {
                            final res = await _api.submitQuiz(
                              playerId: widget.playerId,
                              lessonId: widget.lesson.id,
                              answersByQuizId: _answers,
                            );
                            if (!context.mounted) return;
                            final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => QuizResultScreen(
                                  result: {
                                    'score': res.score,
                                    'correct': res.correct,
                                    'total': res.total,
                                    'passed': res.passed,
                                    'results': res.results,
                                  },
                                ),
                              ),
                            );
                            if (!context.mounted) return;
                            if (res.passed && ok == true) {
                              Navigator.of(context).pop(true);
                            }
                          } finally {
                            if (mounted) setState(() => _submitting = false);
                          }
                        },
                  child: Text(_submitting ? 'Submitting…' : 'Submit'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _questionCard(LearningQuizQuestion q) {
    final selected = _answers[q.id];
    return Container(
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
            q.question,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          for (final opt in q.options)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected == opt
                      ? LearningColors.lime
                      : LearningColors.border,
                ),
                color: selected == opt
                    ? LearningColors.lime.withValues(alpha: 0.10)
                    : Colors.transparent,
              ),
              child: RadioListTile<String>(
                value: opt,
                groupValue: selected,
                onChanged: (v) => setState(() => _answers[q.id] = v ?? ''),
                title: Text(opt),
                dense: true,
                activeColor: LearningColors.limeDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
