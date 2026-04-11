import 'package:flutter/material.dart';

import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/staff_technique_hub.dart';
import '../../user_management/models/user_management_models.dart';

class StaffTechniqueDashboardHubScreen extends StatelessWidget {
  const StaffTechniqueDashboardHubScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final name = '${session.firstName ?? ''} ${session.lastName ?? ''}'.trim();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final searchController = TextEditingController();

    return StaffTechniquePageBackground(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: ListView(
        children: [
          StaffTechniqueHeroCard(
            eyebrow: 'Technical Staff Hub',
            title: name.isEmpty ? 'Kinetic Bench' : name,
            subtitle:
                'Pilote les analyses, la charge, la tactique et la progression de l\'effectif depuis un cockpit unique.',
            icon: Icons.sports_soccer_rounded,
            trailing: _CoachIdentity(name: name, session: session),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Modules actifs',
                  value: '08',
                  icon: Icons.dashboard_customize_rounded,
                  caption: 'IA + suivi terrain',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Priorite jour',
                  value: '03',
                  icon: Icons.flag_circle_rounded,
                  accent: StaffTechniqueHubTheme.warning,
                  caption: 'rapports a valider',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Charge equipe',
                  value: '74%',
                  icon: Icons.monitor_heart_rounded,
                  accent: StaffTechniqueHubTheme.secondary,
                  caption: 'equilibre de la semaine',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Cohesion',
                  value: '8.6',
                  icon: Icons.hub_rounded,
                  accent: StaffTechniqueHubTheme.success,
                  caption: 'base onze type',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StaffTechniqueSearchField(
            controller: searchController,
            hintText: 'Rechercher un module, un joueur ou une mission...',
          ),
          const SizedBox(height: 22),
          const StaffTechniqueSectionTitle(title: 'Focus Modules'),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Analyse Match',
            subtitle:
                'Video, sequences cles et insights IA pour les prochains ajustements.',
            icon: Icons.analytics_rounded,
            route: AppRoutes.analysis,
            tag: 'Live review',
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Planification de Saison',
            subtitle:
                'Construire le macro-cycle et projeter la charge sur plusieurs semaines.',
            icon: Icons.calendar_month_rounded,
            route: AppRoutes.seasonPlanning,
            tag: 'Roadmap',
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Analyse Tactique',
            subtitle:
                'Simuler le XI, lire l\'adversaire et proposer un plan de match.',
            icon: Icons.space_dashboard_rounded,
            route: AppRoutes.tactics,
            tag: 'AI setup',
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Chemie d\'Equipe',
            subtitle:
                'Visualiser les connexions, les tensions et les binomes forts.',
            icon: Icons.hub_outlined,
            route: AppRoutes.chemistry,
            tag: 'Squad fit',
          ),
          const SizedBox(height: 22),
          const StaffTechniqueSectionTitle(title: 'Operations'),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Calendrier & Charge',
            subtitle:
                'Organiser les seances, les matchs et les jours de recup.',
            icon: Icons.event_note_rounded,
            route: AppRoutes.calendar,
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Joueurs',
            subtitle:
                'Suivi de l\'effectif, profils, disponibilites et data individuelle.',
            icon: Icons.groups_rounded,
            route: AppRoutes.players,
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Rapports de Performance',
            subtitle:
                'Centraliser les comptes-rendus, evaluations et signaux du staff.',
            icon: Icons.description_rounded,
            route: AppRoutes.reports,
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Bibliotheque d\'Exercices',
            subtitle:
                'Consulter et lancer des exercices terrain, techniques et cognitifs.',
            icon: Icons.menu_book_rounded,
            route: AppRoutes.exercises,
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Tests Physiques',
            subtitle:
                'Creer des batteries de tests et suivre les seuils de progression.',
            icon: Icons.sports_score_rounded,
            route: AppRoutes.tests,
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            title: 'Labo Cognitif IA',
            subtitle:
                'Observer la fatigue mentale, la vigilance et la lucidite decisionnelle.',
            icon: Icons.psychology_outlined,
            route: AppRoutes.squadCognitiveOverview,
            tag: 'Deep scan',
          ),
        ],
      ),
    );
  }
}

class _CoachIdentity extends StatelessWidget {
  const _CoachIdentity({required this.name, required this.session});

  final String name;
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final initialsSource = name.isNotEmpty ? name : session.email;
    final initial = initialsSource.isNotEmpty
        ? initialsSource.trim()[0].toUpperCase()
        : 'S';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          child: Text(
            initial,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          session.clubName?.trim().isNotEmpty == true
              ? session.clubName!.trim()
              : 'ODIN Club',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.tag,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final shell = AppShellScope.of(context);
    return StaffTechniqueActionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: tag == null ? null : StaffTechniqueStatusChip(label: tag!),
      onTap: () {
        if (shell != null) {
          shell.navigate(route);
        } else {
          Navigator.of(context).pushNamed(route);
        }
      },
    );
  }
}
