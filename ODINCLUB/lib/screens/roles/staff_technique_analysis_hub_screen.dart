import 'package:flutter/material.dart';

import '../../analysis/mobile/match_analysis_mobile_shell.dart';
import '../../analysis/theme/analysis_theme.dart';
import '../../ui/theme/staff_technique_hub.dart';
import '../../user_management/models/user_management_models.dart';

class StaffTechniqueAnalysisHubScreen extends StatelessWidget {
  const StaffTechniqueAnalysisHubScreen({super.key, required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return StaffTechniquePageBackground(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: ListView(
        children: [
          const StaffTechniqueHeroCard(
            eyebrow: 'Match Analysis',
            title: 'Video room',
            subtitle:
                'Lance l\'analyse video, suis les jobs IA et replonge dans l\'historique des matchs traites.',
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Pipeline',
                  value: 'Video + IA',
                  icon: Icons.auto_graph_rounded,
                  caption: 'tracking, heatmaps, events',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StaffTechniqueMetricCard(
                  label: 'Output',
                  value: 'Reports',
                  icon: Icons.playlist_add_check_circle_rounded,
                  accent: StaffTechniqueHubTheme.secondary,
                  caption: 'timeline et overview',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const StaffTechniqueSectionTitle(title: 'Analysis Workflow'),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Importer une video',
            subtitle:
                'Charge un match ou une sequence d\'entrainement pour lancer le pipeline.',
            icon: Icons.upload_file_rounded,
          ),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Suivre les jobs',
            subtitle:
                'Consulte l\'historique, l\'etat de traitement et les erreurs de pipeline.',
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 12),
          const StaffTechniqueActionCard(
            title: 'Lire les insights',
            subtitle:
                'Ouvre les panels IA pour les teams, timelines et tendances de match.',
            icon: Icons.insights_rounded,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                AnalysisPalette.setDarkMode(
                  Theme.of(context).brightness == Brightness.dark,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchAnalysisMobileShell(
                      authToken: session.token,
                      connectedClubName: session.clubName,
                      embedded: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Ouvrir le module d\'analyse'),
            ),
          ),
        ],
      ),
    );
  }
}
