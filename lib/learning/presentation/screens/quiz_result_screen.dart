import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';
import '../widgets/learning_top_bar.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.result,
  });

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] ?? 0) as int? ?? 0;
    final passed = result['passed'] == true;
    final correct = (result['correct'] ?? 0) as int? ?? 0;
    final total = (result['total'] ?? 0) as int? ?? 0;
    final results = (result['results'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: const LearningTopBar(title: 'Quiz Result'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LearningColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: LearningColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed ? 'Passed' : 'Try again',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: passed ? LearningColors.text : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: $score% • $correct/$total',
                  style: TextStyle(color: LearningColors.textMuted, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE9EDF3),
                    valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (results.isNotEmpty) ...[
            const Text('Answers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final r in results) ...[
              _answerCard(r),
              const SizedBox(height: 10),
            ]
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.lime,
                foregroundColor: LearningColors.text,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }

  Widget _answerCard(Map<String, dynamic> r) {
    final ok = r['correct'] == true;
    final q = (r['question'] ?? '').toString();
    final given = (r['givenAnswer'] ?? '').toString();
    final correct = (r['correctAnswer'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ok ? LearningColors.lime : LearningColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? LearningColors.limeDark : Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(child: Text(q, style: const TextStyle(fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 10),
          Text('Your answer: $given', style: TextStyle(color: LearningColors.textMuted)),
          if (!ok) ...[
            const SizedBox(height: 4),
            Text(
              'Correct: $correct',
              style: TextStyle(color: LearningColors.textMuted, fontWeight: FontWeight.w800),
            ),
          ]
        ],
      ),
    );
  }
}
