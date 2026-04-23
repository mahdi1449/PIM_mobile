import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';
import '../utils/lesson_content_parser.dart';
import '../utils/learning_tts.dart';

class VocabularyCards extends StatelessWidget {
  const VocabularyCards({super.key, required this.pairs});

  final List<VocabularyPair> pairs;

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Vocabulary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (final p in pairs.take(18)) ...[
          _VocabularyTile(pair: p),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _VocabularyTile extends StatefulWidget {
  const _VocabularyTile({required this.pair});

  final VocabularyPair pair;

  @override
  State<_VocabularyTile> createState() => _VocabularyTileState();
}

class _VocabularyTileState extends State<_VocabularyTile>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  bool _speaking = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _open = !_open),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LearningColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _open ? LearningColors.lime : LearningColors.border,
            width: _open ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LearningColors.lime.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.translate_rounded,
                color: LearningColors.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pair.term,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _open
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      'Tap to reveal meaning',
                      style: TextStyle(
                        color: LearningColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    secondChild: Text(
                      widget.pair.meaning,
                      style: TextStyle(
                        color: LearningColors.textMuted,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _speaking
                  ? null
                  : () async {
                      setState(() => _speaking = true);
                      try {
                        await LearningTts.speak(widget.pair.term);
                      } finally {
                        if (mounted) setState(() => _speaking = false);
                      }
                    },
              icon: Icon(
                _speaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                color: LearningColors.textMuted,
              ),
              tooltip: 'Listen',
            ),
            Icon(
              _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: LearningColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
