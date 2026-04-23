import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';
import '../utils/lesson_content_parser.dart';

class LessonBlockCard extends StatelessWidget {
  const LessonBlockCard({super.key, required this.title, required this.blocks});

  final String title;
  final List<LessonBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LearningColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final block in blocks) ...[
            _renderBlock(block),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _renderBlock(LessonBlock block) {
    switch (block.type) {
      case LessonBlockType.heading:
        return Text(
          block.title ?? '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: LearningColors.textMuted,
            letterSpacing: 0.6,
          ),
        );
      case LessonBlockType.paragraph:
        return Text(
          block.text ?? '',
          style: const TextStyle(fontSize: 14, height: 1.45),
        );
      case LessonBlockType.bulletList:
        final items = block.items ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LearningColors.limeDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
      case LessonBlockType.task:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LearningColors.lime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LearningColors.lime),
          ),
          child: Row(
            children: [
              Icon(Icons.checklist_rounded, color: LearningColors.text),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.title ?? 'Task',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      case LessonBlockType.vocabulary:
        final pairs = block.vocabulary ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.title ?? 'Vocabulary',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final p in pairs.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.term,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.meaning,
                        style: TextStyle(color: LearningColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }
}
