import 'package:flutter/material.dart';
import '../../models/player_model.dart';
import '../../services/player_service.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/medical_theme.dart';

class StaffMedicalDashboardScreen extends StatefulWidget {
  StaffMedicalDashboardScreen({super.key, required this.session});

  final SessionModel session;

  @override
  State<StaffMedicalDashboardScreen> createState() =>
      _StaffMedicalDashboardScreenState();
}

class _StaffMedicalDashboardScreenState
    extends State<StaffMedicalDashboardScreen> {
  final PlayerService _playerService = PlayerService();
  late Future<List<PlayerModel>> _playersFuture;
  final Set<String> _clearing = {};

  @override
  void initState() {
    super.initState();
    _playersFuture = _playerService.fetchPlayers();
  }

  Future<void> _refreshPlayers() async {
    setState(() {
      _playersFuture = _playerService.fetchPlayers();
    });
    await _playersFuture;
  }

  Future<void> _clearMedical(PlayerModel player) async {
    setState(() {
      _clearing.add(player.id);
    });
    try {
      await _playerService.clearMedical(player.id);
      await _refreshPlayers();
    } finally {
      if (mounted) {
        setState(() {
          _clearing.remove(player.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemFill = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.72)
        : MedicalTheme.surfaceAlt.withValues(alpha: 0.6);
    final itemBorder = Theme.of(
      context,
    ).dividerColor.withValues(alpha: isDark ? 0.78 : 0.9);
    final mutedText = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: isDark ? 0.7 : 0.62);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: name.isEmpty ? 'Med Staff' : name,
            subtitle: 'Suivi medical, tracking vital et prevention.',
          ),
          SizedBox(height: AppSpacing.s16),
          _TrackingOverviewCard(),
          SizedBox(height: AppSpacing.s16),
          _DashboardStatsRow(),
          SizedBox(height: AppSpacing.s16),
          Text(
            'Outils medicaux',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Bracelet medical',
            subtitle: 'Battements de coeur, metabolisme et depense.',
            icon: Icons.watch_rounded,
            route: AppRoutes.medicalWearable,
            accent: MedicalTheme.danger,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Analyse medicale',
            subtitle: 'Selectionner un joueur pour analyser.',
            icon: Icons.monitor_heart,
            route: AppRoutes.medicalPlayers,
            accent: MedicalTheme.primaryBlue,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Injury Camera AI',
            subtitle: 'Scan injury photos for quick insights.',
            icon: Icons.camera_alt_rounded,
            route: AppRoutes.medicalVision,
            accent: MedicalTheme.accentTeal,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Gym Equipment AI',
            subtitle: 'Identify equipment and target muscles.',
            icon: Icons.fitness_center_rounded,
            route: AppRoutes.medicalGymVision,
            accent: MedicalTheme.warning,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Simulation de match',
            subtitle: 'Simuler blessures et charge.',
            icon: Icons.sports_soccer,
            route: AppRoutes.medicalSimulation,
            accent: MedicalTheme.primaryBlue,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Calendrier de recuperation',
            subtitle: 'Suivre les dates de retour estimees.',
            icon: Icons.calendar_month,
            route: AppRoutes.medicalRecoveryCalendar,
            accent: MedicalTheme.success,
          ),
          SizedBox(height: AppSpacing.s12),
          _ActionCard(
            title: 'Historique des matchs',
            subtitle: 'Consulter les simulations deja jouees.',
            icon: Icons.history_rounded,
            route: AppRoutes.medicalMatchHistory,
            accent: MedicalTheme.textSecondary,
          ),
          SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Text(
                'Injured players',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refreshPlayers,
                icon: Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s8),
          FutureBuilder<List<PlayerModel>>(
            future: _playersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Unable to load injured players.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              final players = snapshot.data ?? [];
              final injured = players
                  .where((p) => p.isInjured == true)
                  .toList();
              if (injured.isEmpty) {
                return Text(
                  'No injured players right now.',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }

              return AppCard(
                child: SizedBox(
                  height: 260,
                  child: ListView.separated(
                    itemCount: injured.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final player = injured[index];
                      final isBusy = _clearing.contains(player.id);
                      return Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: itemFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: itemBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    player.lastInjuryType ?? 'Injured',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: mutedText),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _clearMedical(player),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MedicalTheme.danger.withValues(
                                  alpha: 0.12,
                                ),
                                foregroundColor: MedicalTheme.danger,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: MedicalTheme.danger.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              child: isBusy
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      onTap: () {
        if (shell != null) {
          shell.navigate(route);
        } else {
          Navigator.of(context).pushNamed(route);
        }
      },
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: AppSpacing.s4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s8),
          Icon(
            Icons.chevron_right_rounded,
            color: onSurface.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }
}

class _TrackingOverviewCard extends StatelessWidget {
  _TrackingOverviewCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MedicalTheme.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.12),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.watch_rounded, color: Colors.white),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking bracelet live',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: AppSpacing.s4),
                    Text(
                      'Frequence cardiaque et metabolisme des joueurs.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.s16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: Icons.favorite_rounded,
                  label: 'Moy. coeur',
                  value: '86 bpm',
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Metabolisme',
                  value: '78/100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  _HeroMetric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

class _DashboardStatsRow extends StatelessWidget {
  _DashboardStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            value: '12',
            label: 'Joueurs suivis',
            icon: Icons.groups_rounded,
            color: MedicalTheme.primaryBlue,
          ),
        ),
        SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _MiniStatCard(
            value: '3',
            label: 'Alertes actives',
            icon: Icons.notifications_active_rounded,
            color: MedicalTheme.warning,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  _MiniStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: isDark ? 18 : 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: AppSpacing.s8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
