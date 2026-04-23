import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';
import '../widgets/learning_top_bar.dart';

class ExerciseResultScreen extends StatelessWidget {
  const ExerciseResultScreen({
    super.key,
    required this.result,
  });

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] ?? 0).toString();
    final passed = result['passed'] == true;
    final correct = (result['correct'] ?? 0).toString();
    final total = (result['total'] ?? 0).toString();
    final perQuestion = (result['perQuestion'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: const LearningTopBar(title: 'Result'),
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
                    value: (double.tryParse(score) ?? 0) / 100,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE9EDF3),
                    valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (perQuestion.isNotEmpty) ...[
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final q in perQuestion) ...[
              _row(q),
              const SizedBox(height: 10),
            ],
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

  Widget _row(Map<String, dynamic> q) {
    final ok = q['correct'] == true;
    final id = (q['questionId'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ok ? LearningColors.lime : LearningColors.border),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? LearningColors.limeDark : Colors.red.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Question $id',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
