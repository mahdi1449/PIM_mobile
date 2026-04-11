import 'package:flutter/material.dart';

import '../../screens/chemistry/team_chemistry_screen.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueChemistryHubScreen extends StatelessWidget {
  const StaffTechniqueChemistryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return StaffTechniquePageBackground(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: ListView(
        children: [
          const StaffTechniqueHeroCard(
            eyebrow: 'Team Chemistry',
            title: 'Affinites du groupe',
            subtitle:
                'Observe les binomes forts, les conflits latents et les recommandations de onze basees sur la cohesion.',
            icon: Icons.hub_rounded,
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Data',
                  value: 'Pairs',
                  icon: Icons.link_rounded,
                  caption: 'observations et notes',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Reading',
                  value: 'XI score',
                  icon: Icons.ssid_chart_rounded,
                  accent: StaffTechniqueHubTheme.secondary,
                  caption: 'coverage et alerts',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const StaffTechniqueSectionTitle(title: 'Chemistry Workflow'),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Noter une paire',
            subtitle:
                'Enregistre une observation terrain ou une note de staff sur deux joueurs.',
            icon: Icons.rate_review_rounded,
          ),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Analyser les profils',
            subtitle:
                'Laisse l\'IA lire les profils de style et proposer un score de compatibilite.',
            icon: Icons.psychology_alt_rounded,
          ),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Evaluer le onze',
            subtitle:
                'Calcule la cohesion globale, les maillons faibles et les recommandations.',
            icon: Icons.groups_2_rounded,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeamChemistryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Ouvrir le module de chimie'),
            ),
          ),
        ],
      ),
    );
  }
}
