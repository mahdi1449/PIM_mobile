import 'package:flutter/material.dart';

import '../../ui/components/app_section_header.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/medical_theme.dart';
import '../../widgets/bullet_list_card.dart';

class MedicalWearableScreen extends StatefulWidget {
  const MedicalWearableScreen({super.key});

  @override
  State<MedicalWearableScreen> createState() => _MedicalWearableScreenState();
}

class _MedicalWearableScreenState extends State<MedicalWearableScreen> {
  bool _isLive = true;
  final _snapshot = const _WearableSnapshot(
    heartRate: 86,
    metabolicScore: 78,
    metabolicRate: 1.3,
    caloriesPerHour: 540,
    lastSync: '2 min ago',
  );

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
    });
  }

  void _syncNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync requested from bracelet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MedicalThemeScope(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Bracelet medical',
              subtitle: 'Suivi des battements de coeur et metabolisme.',
              action: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _HeroCard(
              snapshot: _snapshot,
              isLive: _isLive,
              onToggleLive: _toggleLive,
              onSync: _syncNow,
            ),
            const SizedBox(height: AppSpacing.s16),
            _LiveMetrics(snapshot: _snapshot, isLive: _isLive),
            const SizedBox(height: AppSpacing.s16),
            _RecentReadings(isLive: _isLive),
            const SizedBox(height: AppSpacing.s16),
            BulletListCard(
              title: 'Recommandations rapides',
              icon: Icons.health_and_safety_rounded,
              items: const [
                'Hydrater avant la prochaine seance (500-700ml).',
                'Limiter les pics de frequence cardiaque > 180 bpm.',
                'Ajoutez 8-10 min de retour au calme apres effort intense.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.snapshot,
    required this.isLive,
    required this.onToggleLive,
    required this.onSync,
  });

  final _WearableSnapshot snapshot;
  final bool isLive;
  final VoidCallback onToggleLive;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MedicalTheme.primaryBlue,
            MedicalTheme.accentTeal.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bracelet connecte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Derniere synchronisation: ${snapshot.lastSync}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatusPill(
                label: isLive ? 'Live' : 'Paused',
                color: isLive
                    ? MedicalTheme.success
                    : scheme.surface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Text(
                isLive ? 'Streaming actif' : 'Streaming en pause',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onToggleLive,
                icon: Icon(isLive ? Icons.pause : Icons.play_arrow),
                label: Text(isLive ? 'Pause' : 'Relancer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: MedicalTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LiveMetrics extends StatelessWidget {
  const _LiveMetrics({required this.snapshot, required this.isLive});

  final _WearableSnapshot snapshot;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final cardWidth = isWide
            ? (constraints.maxWidth - AppSpacing.s12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Battements de coeur',
                value: '${snapshot.heartRate}',
                unit: 'bpm',
                icon: Icons.favorite_rounded,
                accent: MedicalTheme.danger,
                footer: isLive ? 'Live' : 'Last sync',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Score metabolisme',
                value: '${snapshot.metabolicScore}',
                unit: '/100',
                icon: Icons.local_fire_department_rounded,
                accent: MedicalTheme.warning,
                footer: '${snapshot.metabolicRate} kcal/min',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                title: 'Depense energetique',
                value: '${snapshot.caloriesPerHour}',
                unit: 'kcal/h',
                icon: Icons.bolt_rounded,
                accent: MedicalTheme.accentTeal,
                footer: 'Metabolisme actif',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.footer,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accent;
  final String footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MedicalTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MedicalTheme.cardBorder),
        boxShadow: MedicalTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MedicalTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MedicalTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RecentReadings extends StatelessWidget {
  const _RecentReadings({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final samples = const [
      _ReadingSample(time: '09:02', bpm: 94, metabolic: 1.4),
      _ReadingSample(time: '08:57', bpm: 88, metabolic: 1.2),
      _ReadingSample(time: '08:51', bpm: 82, metabolic: 1.1),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MedicalTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Lectures recentes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              _StatusPill(
                label: isLive ? 'Live' : 'Pause',
                color: isLive ? MedicalTheme.success : MedicalTheme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final sample in samples)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(
                    sample.time,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: MedicalTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: MedicalTheme.danger,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${sample.bpm} bpm',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: MedicalTheme.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${sample.metabolic} kcal/min',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WearableSnapshot {
  const _WearableSnapshot({
    required this.heartRate,
    required this.metabolicScore,
    required this.metabolicRate,
    required this.caloriesPerHour,
    required this.lastSync,
  });

  final int heartRate;
  final int metabolicScore;
  final double metabolicRate;
  final int caloriesPerHour;
  final String lastSync;
}

class _ReadingSample {
  const _ReadingSample({
    required this.time,
    required this.bpm,
    required this.metabolic,
  });

  final String time;
  final int bpm;
  final double metabolic;
}
