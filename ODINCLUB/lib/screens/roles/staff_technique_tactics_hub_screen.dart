import 'package:flutter/material.dart';

import '../../tactics/screens/tactics_board_screen.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueTacticsHubScreen extends StatelessWidget {
  const StaffTechniqueTacticsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return StaffTechniquePageBackground(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: ListView(
        children: [
          const StaffTechniqueHeroCard(
            eyebrow: 'Tactical Lab',
            title: 'Preparation adversaire',
            subtitle:
                'Construis un plan de match, importe les infos adverses et genere un onze de depart adapte.',
            icon: Icons.space_dashboard_rounded,
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Input',
                  value: 'Scout feed',
                  icon: Icons.radar_rounded,
                  caption: 'style, faiblesses, effectif',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Output',
                  value: 'Starting XI',
                  icon: Icons.groups_3_rounded,
                  accent: StaffTechniqueHubTheme.secondary,
                  caption: 'consignes et roles',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const StaffTechniqueSectionTitle(title: 'Tactical Workflow'),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Profil rapide',
            subtitle:
                'Choisis un style adverse pour obtenir une premiere proposition tactique.',
            icon: Icons.flash_on_rounded,
          ),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Import detaille',
            subtitle:
                'Colle un rapport JSON ou saisis forces et faiblesses pour enrichir le plan.',
            icon: Icons.data_object_rounded,
          ),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Consignes individuelles',
            subtitle:
                'Ouvre le tableau pour voir les roles, ajustements et variantes selon le score.',
            icon: Icons.assignment_turned_in_rounded,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TacticsBoardScreen()),
                );
              },
              icon: const Icon(Icons.open_in_full_rounded),
              label: const Text('Ouvrir le tableau tactique'),
            ),
          ),
        ],
      ),
    );
  }
}
