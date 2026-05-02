import 'package:flutter/material.dart';

import '../../screens/login_screen.dart';
import '../../services/api_service.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/components/loading_state.dart';
import '../../ui/theme/app_spacing.dart';
import '../models/media_training_models.dart';
import '../services/media_training_service.dart';
import 'media_training_lesson_screen.dart';

class MediaTrainingHomeScreen extends StatefulWidget {
  const MediaTrainingHomeScreen({
    super.key,
    this.authToken,
  });

  final String? authToken;

  @override
  State<MediaTrainingHomeScreen> createState() =>
      _MediaTrainingHomeScreenState();
}

class _MediaTrainingHomeScreenState extends State<MediaTrainingHomeScreen> {
  final MediaTrainingService _service = MediaTrainingService();
  final ApiService _apiService = ApiService();

  MediaTrainingDashboard? _dashboard;
  MediaTrainingRoadmap? _roadmap;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getDashboard(authToken: widget.authToken),
        _service.getRoadmap(authToken: widget.authToken),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as MediaTrainingDashboard;
        _roadmap = results[1] as MediaTrainingRoadmap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_isUnauthorizedError(e)) {
        await _redirectToLogin();
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isUnauthorizedError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('unauthorized') ||
        text.contains('authentication required') ||
        text.contains('invalid token');
  }

  Future<void> _redirectToLogin() async {
    await _apiService.removeToken();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expiree. Merci de vous reconnecter.'),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openLesson(String lessonId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaTrainingLessonScreen(
          lessonId: lessonId,
          authToken: widget.authToken,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingState(
        message: 'Chargement du parcours media training...',
      );
    }

    if (_error != null || _dashboard == null || _roadmap == null) {
      return EmptyState(
        title: 'Media Training indisponible',
        message: _error ?? 'Impossible de charger le module.',
        icon: Icons.mic_external_on_outlined,
        action: ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recharger'),
        ),
      );
    }

    final dashboard = _dashboard!;
    final roadmap = _roadmap!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
        children: [
          AppSectionHeader(
            title: 'Media Training',
            subtitle: 'Parcours media.',
            action: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          _OverviewHero(
            dashboard: dashboard,
            onContinue: dashboard.currentLesson == null
                ? null
                : () => _openLesson(dashboard.currentLesson!.id),
          ),
          const SizedBox(height: AppSpacing.s16),
          _CommunicationProfileCard(profile: dashboard.communicationProfile),
          const SizedBox(height: AppSpacing.s16),
          if (dashboard.currentLesson != null) ...[
            _CurrentLessonCard(
              lesson: dashboard.currentLesson!,
              onTap: () => _openLesson(dashboard.currentLesson!.id),
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (dashboard.recentSessions.isNotEmpty) ...[
            _SectionTitle(
              title: 'Dernieres simulations',
              subtitle: 'Recentes.',
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final session in dashboard.recentSessions) ...[
              _RecentSessionCard(session: session),
              const SizedBox(height: AppSpacing.s12),
            ],
            const SizedBox(height: AppSpacing.s8),
          ],
          _SectionTitle(
            title: 'Roadmap',
            subtitle: 'Parcours.',
          ),
          const SizedBox(height: AppSpacing.s12),
          for (final phase in roadmap.phases) ...[
            _PhaseCard(
              phase: phase,
              onLessonTap: _openLesson,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
        ],
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.dashboard,
    this.onContinue,
  });

  final MediaTrainingDashboard dashboard;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = dashboard.roadmapSummary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.84),
            scheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeroBadge(label: dashboard.communicationTier),
              const Spacer(),
              Text(
                '${summary.progressPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          const Text(
            'Progression',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            '${summary.completedLessons}/${summary.totalLessons} lecons',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(
                label: 'Completees',
                value: '${summary.completedLessons}',
              ),
              _HeroStat(
                label: 'Maitrisees',
                value: '${summary.masteredLessons}',
              ),
              _HeroStat(
                label: 'Verrouillees',
                value: '${summary.lockedLessons}',
              ),
            ],
          ),
          if (summary.nextRecommendedLessonTitle != null) ...[
            const SizedBox(height: AppSpacing.s16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suite',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          summary.nextRecommendedLessonTitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onContinue != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ElevatedButton.icon(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: scheme.primary,
              ),
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('Continuer le parcours'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommunicationProfileCard extends StatelessWidget {
  const _CommunicationProfileCard({required this.profile});

  final Map<String, double?> profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil de communication',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Vue rapide.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: profile.entries.map((entry) {
                final value = entry.value ?? 0;
                return SizedBox(
                  width: 160,
                  child: _MetricChip(
                    label: _metricLabel(entry.key),
                    value: value,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLessonCard extends StatelessWidget {
  const _CurrentLessonCard({
    required this.lesson,
    required this.onTap,
  });

  final MediaTrainingLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'A suivre',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            Text(lesson.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InlineChip(label: lesson.format),
                _InlineChip(label: lesson.level),
                _InlineChip(label: '${lesson.estimatedMinutes} min'),
              ],
            ),
            if ((lesson.recommendedAction ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                lesson.recommendedAction!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.s4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({required this.session});

  final MediaTrainingSessionSummary session;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, session.overallScore);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                session.status == 'EVALUATED'
                    ? Icons.verified_rounded
                    : Icons.hourglass_bottom_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.lessonTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniTag(
                        label: _sessionStatusLabel(session.status),
                        color: color,
                      ),
                      if (session.readinessLevel != null)
                        _MiniTag(
                          label: session.readinessLevel!,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      if (session.overallScore != null)
                        _MiniTag(
                          label:
                              'Score ${session.overallScore!.toStringAsFixed(0)}',
                          color: color,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.onLessonTap,
  });

  final MediaTrainingPhase phase;
  final ValueChanged<String> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _phaseLabel(phase.phase),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${phase.progressPercent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '${phase.completed}/${phase.lessons.length} lecons · ${phase.mastered} maitrisees',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.s12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (phase.progressPercent / 100).clamp(0, 1),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            for (final lesson in phase.lessons) ...[
              _LessonCard(
                lesson: lesson,
                onTap: () => onLessonTap(lesson.id),
              ),
              if (lesson != phase.lessons.last)
                const SizedBox(height: AppSpacing.s12),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.onTap,
  });

  final MediaTrainingLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(context, lesson.bestScore);
    return InkWell(
      onTap: lesson.unlocked ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lesson.unlocked
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.03)
              : Theme.of(context).dividerColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: lesson.unlocked
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: lesson.unlocked
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.18),
                  child: Text(
                    '${lesson.order}',
                    style: TextStyle(
                      color: lesson.unlocked
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        '${lesson.format} · ${lesson.level} · ${lesson.estimatedMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(lesson: lesson),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(lesson.summary, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (lesson.bestScore != null)
                  _MiniTag(
                    label: 'Score ${lesson.bestScore!.toStringAsFixed(0)}',
                    color: scoreColor,
                  ),
                _MiniTag(
                  label:
                      '${lesson.attempts} tentative${lesson.attempts > 1 ? 's' : ''}',
                  color: Theme.of(context).colorScheme.primary,
                ),
                ...lesson.skillTags.take(2).map(
                      (tag) => _MiniTag(
                        label: tag.replaceAll('_', ' '),
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              lesson.unlocked
                  ? (lesson.recommendedAction ?? '')
                  : (lesson.lockedReason ?? 'Lecon verrouillee'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(context, value);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (value / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.lesson});

  final MediaTrainingLesson lesson;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    if (!lesson.unlocked) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
      label = 'Verrouillee';
    } else if (lesson.mastered) {
      color = Colors.green;
      label = 'Maitrisee';
    } else if (lesson.completed) {
      color = Colors.orange;
      label = 'Faite';
    } else {
      color = Theme.of(context).colorScheme.primary;
      label = 'En cours';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _phaseLabel(String phase) {
  switch (phase) {
    case 'FOUNDATIONS':
      return 'Fondations';
    case 'MATCHDAY_COMMUNICATION':
      return 'Communication de match';
    case 'PRESSURE_MANAGEMENT':
      return 'Gestion de pression';
    case 'LEADERSHIP':
      return 'Leadership';
    default:
      return phase;
  }
}

String _metricLabel(String metric) {
  switch (metric) {
    case 'messageControl':
      return 'Controle du message';
    case 'emotionalControl':
      return 'Controle emotionnel';
    case 'pressureManagement':
      return 'Gestion pression';
    case 'clarity':
      return 'Clarte';
    case 'discipline':
      return 'Discipline';
    case 'structure':
      return 'Structure';
    default:
      return metric;
  }
}

String _sessionStatusLabel(String status) {
  switch (status) {
    case 'EVALUATED':
      return 'Evaluee';
    case 'CREATED':
      return 'Creee';
    default:
      return status;
  }
}

Color _scoreColor(BuildContext context, double? score) {
  final value = score ?? 0;
  if (value >= 80) return Colors.green;
  if (value >= 65) return Colors.orange;
  if (value > 0) return Colors.redAccent;
  return Theme.of(context).colorScheme.primary;
}
