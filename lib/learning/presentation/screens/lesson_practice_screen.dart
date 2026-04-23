import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';
import '../utils/lesson_content_parser.dart';

class LessonPracticeScreen extends StatefulWidget {
  const LessonPracticeScreen({super.key, required this.pairs});

  final List<VocabularyPair> pairs;

  @override
  State<LessonPracticeScreen> createState() => _LessonPracticeScreenState();
}

class _LessonPracticeScreenState extends State<LessonPracticeScreen> {
  late final List<_Mcq> _questions;
  int _index = 0;
  int _correct = 0;
  String? _picked;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions(widget.pairs);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: LearningColors.surface,
        appBar: AppBar(
          title: const Text('Practice'),
          backgroundColor: LearningColors.surface,
        ),
        body: const Center(child: Text('No vocabulary found in this lesson.')),
      );
    }

    final q = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: AppBar(
        title: const Text('Practice Quiz'),
        backgroundColor: LearningColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE9EDF3),
                valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Question ${_index + 1}/${_questions.length}',
              style: TextStyle(
                color: LearningColors.textMuted,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What is the meaning of:',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LearningColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LearningColors.border),
              ),
              child: Text(
                q.term,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final opt in q.options) ...[
              _option(opt, q.correct),
              const SizedBox(height: 10),
            ],
            const Spacer(),
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
                onPressed: _picked == null ? null : _next,
                child: Text(
                  _index == _questions.length - 1 ? 'Finish' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(String value, String correct) {
    final picked = _picked;
    final isPicked = picked == value;
    final isCorrect = value == correct;
    final show = picked != null;

    Color border = LearningColors.border;
    Color bg = LearningColors.card;
    if (show && isPicked && isCorrect) {
      border = LearningColors.success;
      bg = LearningColors.success.withValues(alpha: 0.10);
    } else if (show && isPicked && !isCorrect) {
      border = LearningColors.warning;
      bg = LearningColors.warning.withValues(alpha: 0.10);
    } else if (show && !isPicked && isCorrect) {
      border = LearningColors.success.withValues(alpha: 0.6);
      bg = LearningColors.success.withValues(alpha: 0.06);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: picked == null ? () => setState(() => _picked = value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(
              show
                  ? (isCorrect
                        ? Icons.check_circle_rounded
                        : (isPicked
                              ? Icons.cancel_rounded
                              : Icons.circle_outlined))
                  : (isPicked
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded),
              color: show
                  ? (isCorrect
                        ? LearningColors.success
                        : (isPicked
                              ? LearningColors.warning
                              : LearningColors.textMuted))
                  : (isPicked
                        ? LearningColors.limeDark
                        : LearningColors.textMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    final q = _questions[_index];
    if (_picked == q.correct) _correct += 1;
    if (_index == _questions.length - 1) {
      final score = (_correct / _questions.length * 100).round();
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Done'),
          content: Text('Score: $score% ($_correct/${_questions.length})'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ).then((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    setState(() {
      _index += 1;
      _picked = null;
    });
  }

  List<_Mcq> _buildQuestions(List<VocabularyPair> pairs) {
    final pool = pairs
        .where((p) => p.term.isNotEmpty && p.meaning.isNotEmpty)
        .toList();
    if (pool.length < 4) return const [];
    final rnd = Random();
    pool.shuffle(rnd);
    final take = pool.take(8).toList();
    return take.map((p) {
      final distractors = pool.where((x) => x != p).toList()..shuffle(rnd);
      final opts = <String>[
        p.meaning,
        ...distractors.take(3).map((d) => d.meaning),
      ];
      opts.shuffle(rnd);
      return _Mcq(term: p.term, correct: p.meaning, options: opts);
    }).toList();
  }
}

class _Mcq {
  final String term;
  final String correct;
  final List<String> options;

  const _Mcq({
    required this.term,
    required this.correct,
    required this.options,
  });
}
