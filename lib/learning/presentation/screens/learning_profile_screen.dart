import 'package:flutter/material.dart';
import '../../../user_management/models/user_management_models.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_progress.dart';
import '../../theme/learning_colors.dart';

class LearningProfileScreen extends StatefulWidget {
  const LearningProfileScreen({
    super.key,
    required this.session,
    required this.playerId,
  });

  final SessionModel session;
  final String playerId;

  @override
  State<LearningProfileScreen> createState() => _LearningProfileScreenState();
}

class _LearningProfileScreenState extends State<LearningProfileScreen> {
  final LearningApi _api = LearningApi();

  Future<List<LearningProgress>> _load() =>
      _api.playerProgress(widget.playerId);

  @override
  Widget build(BuildContext context) {
    final displayName =
        '${widget.session.firstName ?? ''} ${widget.session.lastName ?? ''}'
            .trim();
    return FutureBuilder<List<LearningProgress>>(
      future: _load(),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const <LearningProgress>[];
        final courses = progress.length;
        final completed = progress.where((p) => p.completed).length;
        final avgQuiz = progress.isEmpty
            ? 0
            : (progress.fold<int>(0, (sum, p) => sum + p.quizAverage) /
                      progress.length)
                  .round();
        final totalHours = progress.isEmpty
            ? 0
            : (progress.fold<int>(0, (sum, p) => sum + p.progressPercentage) /
                      100 *
                      1.2)
                  .round();

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: LearningColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: LearningColors.border),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: LearningColors.lime.withValues(
                            alpha: 0.18,
                          ),
                          child: Text(
                            (displayName.isEmpty
                                ? 'A'
                                : displayName[0].toUpperCase()),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: LearningColors.text,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: LearningColors.navy,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName.isEmpty ? 'Player' : displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Focused on improving technical football vocabulary and communication.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: LearningColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _metricCard('Total Hours', '$totalHours'),
                        const SizedBox(width: 10),
                        _metricCard('Courses', '$courses'),
                        const SizedBox(width: 10),
                        _metricCard('Quiz Avg', '$avgQuiz%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View Gallery',
                    style: TextStyle(
                      color: LearningColors.limeDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _badge('Early Bird', completed >= 1),
                _badge('Perfect Quiz', avgQuiz >= 90),
                _badge('Grammar Pro', avgQuiz >= 80),
                _badge('Streak King', completed >= 3),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Completed Courses ($completed)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
                'Failed to load progress: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            for (final p in progress.where((p) => p.completed)) ...[
              _certificateTile(p),
              const SizedBox(height: 12),
            ],
            if (progress.where((p) => p.completed).isEmpty &&
                snapshot.connectionState == ConnectionState.done)
              const Text('No certificates yet. Complete a course to earn one.'),
          ],
        );
      },
    );
  }

  Widget _metricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: LearningColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, bool active) {
    final color = active ? LearningColors.lime : const Color(0xFFE5E7EB);
    final iconColor = active ? LearningColors.text : LearningColors.textMuted;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.95),
          ),
          child: Icon(
            active ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active ? LearningColors.text : LearningColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _certificateTile(LearningProgress p) {
    final title = p.course?['title']?.toString() ?? 'Course';
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
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.verified_rounded,
              color: LearningColors.text,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Credential • ${p.quizAverage}% avg',
                  style: TextStyle(
                    color: LearningColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
            color: LearningColors.textMuted,
          ),
        ],
      ),
    );
  }
}
