import 'package:flutter/material.dart';
import '../../user_management/models/user_management_models.dart';
import '../../ui/components/app_section_header.dart';
import '../../ui/navigation/app_routes.dart';
import '../../ui/shell/app_shell.dart';
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
                iconColor: _StaffTechPalette.neonBlue,
                onTap: () => navigateTo(AppRoutes.analysis),
              ),
              _QuickActionTile(
                title: 'CHEMIE D\'EQUIPE',
                subtitle: 'Cohesion groupe',
                icon: Icons.hub_outlined,
                iconColor: _StaffTechPalette.mint,
                onTap: () => navigateTo(AppRoutes.chemistry),
              ),
              _QuickActionTile(
                title: 'CALENDRIER',
                subtitle: 'Gestion charge',
                icon: Icons.calendar_month_rounded,
                iconColor: _StaffTechPalette.orange,
                onTap: () => navigateTo(AppRoutes.calendar),
              ),
              _QuickActionTile(
                title: 'JOUEURS',
                subtitle: 'Roster complet',
                icon: Icons.groups_rounded,
                iconColor: _StaffTechPalette.neonBlue,
                onTap: () => navigateTo(AppRoutes.players),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          const Text(
            'RESSOURCES & DONNEES',
            style: TextStyle(
              color: _StaffTechPalette.sectionLabel,
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
            iconColor: _StaffTechPalette.neonBlue,
            onTap: () => navigateTo(AppRoutes.reports),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Bibliotheque d\'exercices',
            subtitle: 'Exercices et modeles d\'entrainement',
            icon: Icons.menu_book_rounded,
            iconColor: _StaffTechPalette.mint,
            onTap: () => navigateTo(AppRoutes.exercises),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Planification de Saison',
            subtitle: 'Generer la saison avec l\'IA',
            icon: Icons.route_rounded,
            iconColor: _StaffTechPalette.violetBlue,
            onTap: () => navigateTo(AppRoutes.seasonPlanning),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Analyse Tactique & Adversaire',
            subtitle: 'XI de depart sur-mesure',
            icon: Icons.sports_soccer_rounded,
            iconColor: _StaffTechPalette.orange,
            onTap: () => navigateTo(AppRoutes.tactics),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Tests physiques',
            subtitle: 'Creer et gerer les tests',
            icon: Icons.fitness_center_rounded,
            iconColor: _StaffTechPalette.neonBlue,
            onTap: () => navigateTo(AppRoutes.tests),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ResourceActionTile(
            title: 'Labo Cognitif IA',
            subtitle: 'Evaluer la fatigue mentale',
            icon: Icons.psychology_outlined,
            iconColor: _StaffTechPalette.mint,
            onTap: () => navigateTo(AppRoutes.squadCognitiveOverview),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_StaffTechPalette.cardGradA, _StaffTechPalette.cardGradB],
          ),
          border: Border.all(color: _StaffTechPalette.cardBorder),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _StaffTechPalette.iconSurface,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: AppSpacing.s4),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: _StaffTechPalette.textPrimary,
                fontSize: 13,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: _StaffTechPalette.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_StaffTechPalette.cardGradA, _StaffTechPalette.cardGradB],
          ),
          border: Border.all(color: _StaffTechPalette.cardBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _StaffTechPalette.iconSurface,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _StaffTechPalette.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    subtitle.toUpperCase(),
                    style: const TextStyle(
                      color: _StaffTechPalette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _StaffTechPalette.chevron,
              size: 30,
            ),
          ],
        ),
      ),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_StaffTechPalette.cardGradA, _StaffTechPalette.cardGradB],
        ),
        border: Border.all(color: _StaffTechPalette.mint, width: 1.4),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SCORE PERFORMANCE',
                  style: TextStyle(
                    color: _StaffTechPalette.mint,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '+${deltaPct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _StaffTechPalette.mint,
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
                style: const TextStyle(
                  color: _StaffTechPalette.textPrimary,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: _StaffTechPalette.textMuted,
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
              color: _StaffTechPalette.mint,
              backgroundColor: _StaffTechPalette.softTrack,
            ),
          ),
        ],
      ),
    );
  }
}

abstract class _StaffTechPalette {
  static const Color textPrimary = Color(0xFFDDE8FF);
  static const Color textMuted = Color(0xFF8CA1C7);
  static const Color sectionLabel = Color(0xFF5E74A3);
  static const Color chevron = Color(0xFF5A6F97);
  static const Color iconSurface = Color(0xFF1D2A48);
  static const Color softTrack = Color(0xFF10203D);
  static const Color cardGradA = Color(0xFF192744);
  static const Color cardGradB = Color(0xFF1B2A46);
  static const Color cardBorder = Color(0xFF2A3E61);
  static const Color neonBlue = Color(0xFF4A8DFF);
  static const Color violetBlue = Color(0xFF6E88FF);
  static const Color mint = Color(0xFF50E4BE);
  static const Color orange = Color(0xFFFFB14A);
}
