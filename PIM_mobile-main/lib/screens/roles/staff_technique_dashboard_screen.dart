import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';

class StaffTechniqueDashboardScreen extends StatelessWidget {
  const StaffTechniqueDashboardScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    final shell = AppShellScope.of(context);

    void navigateTo(String route) {
      if (shell != null) {
        shell.navigate(route);
      } else {
        Navigator.of(context).pushNamed(route);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: name.isEmpty ? 'Staff Technique' : name,
            subtitle: 'Analyse et performance de l\'equipe.',
          ),
          const SizedBox(height: AppSpacing.s16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.s8,
            crossAxisSpacing: AppSpacing.s8,
            childAspectRatio: 1.2,
            children: [
              _QuickActionTile(
                title: 'ANALYSE MATCH',
                subtitle: 'Video + IA',
                icon: Icons.analytics_rounded,
                iconColor: AppColors.primaryLight,
                onTap: () => navigateTo(AppRoutes.analysis),
              ),
              _QuickActionTile(
                title: 'CHEMIE D\'EQUIPE',
                subtitle: 'Cohesion groupe',
                icon: Icons.hub_outlined,
                iconColor: AppColors.success,
                onTap: () => navigateTo(AppRoutes.chemistry),
              ),
              _QuickActionTile(
                title: 'CALENDRIER',
                subtitle: 'Gestion charge',
                icon: Icons.calendar_month_rounded,
                iconColor: AppColors.warning,
                onTap: () => navigateTo(AppRoutes.calendar),
              ),
              _QuickActionTile(
                title: 'JOUEURS',
                subtitle: 'Roster complet',
                icon: Icons.groups_rounded,
                iconColor: AppColors.primaryLight,
                onTap: () => navigateTo(AppRoutes.players),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'RESSOURCES & DONNEES',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.56),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Tests & Rapports',
            subtitle: 'Performance et evaluations',
            icon: Icons.assessment_rounded,
            iconColor: AppColors.primaryLight,
            onTap: () => navigateTo(AppRoutes.reports),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Bibliotheque d\'exercices',
            subtitle: 'Exercices et modeles d\'entrainement',
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.success,
            onTap: () => navigateTo(AppRoutes.exercises),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Planification de Saison',
            subtitle: 'Generer la saison avec l\'IA',
            icon: Icons.route_rounded,
            iconColor: AppColors.secondary,
            onTap: () => navigateTo(AppRoutes.seasonPlanning),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Analyse Tactique & Adversaire',
            subtitle: 'XI de depart sur-mesure',
            icon: Icons.sports_soccer_rounded,
            iconColor: AppColors.warning,
            onTap: () => navigateTo(AppRoutes.tactics),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Tests physiques',
            subtitle: 'Creer et gerer les tests',
            icon: Icons.fitness_center_rounded,
            iconColor: AppColors.primaryLight,
            onTap: () => navigateTo(AppRoutes.tests),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Labo Cognitif IA',
            subtitle: 'Evaluer la fatigue mentale',
            icon: Icons.psychology_outlined,
            iconColor: AppColors.success,
            onTap: () => navigateTo(AppRoutes.squadCognitiveOverview),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Voyages & Logistique',
            subtitle: 'Gestion des déplacements',
            icon: Icons.flight_takeoff_rounded,
            iconColor: AppColors.primaryLight,
            onTap: () => navigateTo(AppRoutes.travelList),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Gamification & Classement',
            subtitle: 'Récompenses et points',
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.warning,
            onTap: () => navigateTo(AppRoutes.gamification),
          ),
          const SizedBox(height: AppSpacing.s16),
          const _PerformanceScoreCard(score: 88, deltaPct: 4.2),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      accentColor: iconColor,
      padding: const EdgeInsets.all(12),
      trailing: const SizedBox.shrink(),
    );
  }
}

class _ResourceActionTile extends StatelessWidget {
  const _ResourceActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      icon: icon,
      title: title,
      subtitle: subtitle,
      accentColor: iconColor,
    );
  }
}

class _PerformanceScoreCard extends StatelessWidget {
  const _PerformanceScoreCard({required this.score, required this.deltaPct});

  final int score;
  final double deltaPct;

  @override
  Widget build(BuildContext context) {
    final ratio = (score / 100).clamp(0.0, 1.0);
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SCORE PERFORMANCE',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.success,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '+${deltaPct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '/100',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.58),
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio,
              color: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}
