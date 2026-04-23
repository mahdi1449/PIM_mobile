import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../../data/models/learning_lesson_detail.dart';
import '../../theme/learning_colors.dart';
import '../providers/learning_providers.dart';
import '../widgets/learning_top_bar.dart';
import 'exercise_screen.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({
    super.key,
    required this.playerId,
    required this.lessonId,
  });

  final String playerId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(
      learningLessonDetailProvider((lessonId: lessonId, playerId: playerId)),
    );

    return Scaffold(
      backgroundColor: LearningColors.surface,
      appBar: LearningTopBar(
        title: 'ODIN',
        avatarLetter: playerId.isNotEmpty ? playerId[0] : 'O',
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load lesson: $e')),
        data: (detail) => _LessonDetailBody(
          playerId: playerId,
          detail: detail,
        ),
      ),
    );
  }
}

class _LessonDetailBody extends StatelessWidget {
  const _LessonDetailBody({
    required this.playerId,
    required this.detail,
  });

  final String playerId;
  final LearningLessonDetail detail;

  @override
  Widget build(BuildContext context) {
    final lesson = detail.lesson;
    final title = (lesson['title'] ?? '').toString();
    final imageUrls = (lesson['imageUrls'] as List? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        _heroCard(title: title, imageUrls: imageUrls),
        const SizedBox(height: 14),
        if ((lesson['introPrompt'] ?? '').toString().trim().isNotEmpty)
          _infoCard(
            title: 'Lesson Intro',
            text: (lesson['introPrompt'] ?? '').toString(),
            icon: Icons.flag_outlined,
          ),
        if ((lesson['introPrompt'] ?? '').toString().trim().isNotEmpty)
          const SizedBox(height: 14),
        if (detail.sections.isNotEmpty) ...[
          const Text('Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final s in detail.sections) ...[
            _sectionCard(s),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
        ],
        if (detail.vocabulary.isNotEmpty) ...[
          const Text('Vocabulary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final v in detail.vocabulary.take(24)) ...[
            _vocabTile(v),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
        ],
        const Text('Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (detail.exercises.isEmpty)
          const _EmptyCard(text: 'No exercises found for this lesson.'),
        for (final ex in detail.exercises) ...[
          _exerciseCard(context, ex),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _heroCard({required String title, required List<String> imageUrls}) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: LearningColors.navy,
      ),
      child: Stack(
        children: [
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  final url = imageUrls[index];
                  return CachedNetworkImage(
                    imageUrl: url.startsWith('http') ? url : '${AppConfig.baseUrl}$url',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: LearningColors.navy2),
                    errorWidget: (_, __, ___) => Container(color: LearningColors.navy2),
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
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              title,
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
    );
  }

  Widget _infoCard({
    required String title,
    required String text,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: LearningColors.lime.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: LearningColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(text, style: TextStyle(color: LearningColors.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(LearningLessonSection section) {
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
          Text(section.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          for (final b in section.blocks) ...[
            if ((b.title ?? '').trim().isNotEmpty)
              Text(
                b.title!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: LearningColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            if ((b.text ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  b.text!,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            if (b.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: b.items
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
                                child: Text(e, style: const TextStyle(height: 1.35)),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _vocabTile(LearningVocabularyItem item) {
    final fr = (item.notes['fr'] ?? '').toString().trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
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
            child: Icon(Icons.translate_rounded, color: LearningColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.term, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                if (item.definition.trim().isNotEmpty)
                  Text(item.definition, style: TextStyle(color: LearningColors.textMuted, height: 1.25)),
                if (fr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('FR: $fr', style: TextStyle(color: LearningColors.textMuted, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(BuildContext context, LearningExercise ex) {
    final latest = ex.latestAttempt;
    final score = latest != null ? (latest['score'] ?? 0).toString() : null;
    final passed = latest != null ? latest['passed'] == true : false;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseScreen(playerId: playerId, exercise: ex),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LearningColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LearningColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ex.graded ? LearningColors.lime.withValues(alpha: 0.18) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                ex.graded ? Icons.checklist_rounded : Icons.notes_rounded,
                color: LearningColors.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    ex.type.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w900,
                      color: LearningColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: passed ? LearningColors.lime.withValues(alpha: 0.18) : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: passed ? LearningColors.lime : LearningColors.border),
                ),
                child: Text(
                  '$score%',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: LearningColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
      ),
      child: Text(text, style: TextStyle(color: LearningColors.textMuted)),
    );
  }
}
