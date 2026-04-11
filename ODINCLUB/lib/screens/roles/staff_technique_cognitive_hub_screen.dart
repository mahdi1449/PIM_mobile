import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sports_performance/cognitive_lab/providers/cognitive_lab_provider.dart';
import '../../sports_performance/cognitive_lab/screens/cognitive_dashboard_screen.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueCognitiveHubScreen extends StatefulWidget {
  const StaffTechniqueCognitiveHubScreen({super.key});

  @override
  State<StaffTechniqueCognitiveHubScreen> createState() =>
      _StaffTechniqueCognitiveHubScreenState();
}

class _StaffTechniqueCognitiveHubScreenState
    extends State<StaffTechniqueCognitiveHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CognitiveLabProvider>().fetchSquadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return StaffTechniquePageBackground(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: Consumer<CognitiveLabProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = provider.squadSummary;
          final atRisk = provider.atRiskPlayers.cast<Map<String, dynamic>>();
          final allSessions = provider.allSessions.cast<Map<String, dynamic>>();
          final totalPlayers = summary.values.fold<int>(
            0,
            (sum, value) => sum + ((value as num?)?.toInt() ?? 0),
          );

          return RefreshIndicator(
            onRefresh: provider.fetchSquadOverview,
            child: ListView(
              children: [
                StaffTechniqueHeroCard(
                  eyebrow: 'Cognitive Lab',
                  title: 'Squad readiness',
                  subtitle:
                      'Lis la charge mentale collective, isole les profils a risque et ouvre les fiches individuelles.',
                  icon: Icons.psychology_outlined,
                  trailing: StaffTechniqueStatusChip(
                    label: '${atRisk.length} a risque',
                    color: atRisk.isEmpty
                        ? StaffTechniqueHubTheme.success
                        : StaffTechniqueHubTheme.warning,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Tests',
                        value: '$totalPlayers',
                        icon: Icons.fact_check_outlined,
                        caption: 'joueurs evalues',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Sessions',
                        value: '${allSessions.length}',
                        icon: Icons.history_rounded,
                        accent: StaffTechniqueHubTheme.secondary,
                        caption: 'historique charge',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const StaffTechniqueSectionTitle(title: 'Summary'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: summary.entries
                      .where((entry) => (entry.value as num?)?.toInt() != 0)
                      .map(
                        (entry) => SizedBox(
                          width: 156,
                          child: StaffTechniqueMetricCard(
                            label: entry.key,
                            value: '${entry.value}',
                            icon: Icons.radar_rounded,
                            accent: _statusColor(entry.key),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                const StaffTechniqueSectionTitle(title: 'At-Risk Players'),
                const SizedBox(height: 12),
                if (atRisk.isEmpty)
                  const StaffTechniqueEmptyState(
                    icon: Icons.verified_user_outlined,
                    title: 'Aucun signal critique',
                    subtitle:
                        'Le groupe ne presente pas de fatigue cognitive urgente.',
                  )
                else
                  ...atRisk.map(_buildPlayerCard),
                const SizedBox(height: 22),
                const StaffTechniqueSectionTitle(title: 'Recent Assessments'),
                const SizedBox(height: 12),
                if (allSessions.isEmpty)
                  const StaffTechniqueEmptyState(
                    icon: Icons.timeline_outlined,
                    title: 'Aucune session recente',
                    subtitle:
                        'Les evaluations cognitives apparaitront ici apres les prochains tests.',
                  )
                else
                  ...allSessions.take(10).map(_buildPlayerCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final playerName = (player['playerName'] ?? 'Player').toString();
    final status = (player['status'] ?? 'unknown').toString();
    final recommendation = (player['recommendation'] ?? 'No recommendation')
        .toString();
    final playerId = (player['playerId'] ?? '').toString();
    final score = player['mentalScore'];
    final scoreText = score is num ? '${score.toStringAsFixed(0)}%' : 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: playerName,
        subtitle:
            '$scoreText  •  ${player['playerPosition'] ?? ''}  •  $recommendation',
        icon: Icons.person_outline_rounded,
        trailing: StaffTechniqueStatusChip(
          label: status.toUpperCase(),
          color: _statusColor(status),
        ),
        onTap: () {
          final session = AppShellScope.of(context)?.session;
          if (session == null || playerId.isEmpty) {
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CognitiveDashboardScreen(
                session: session,
                targetPlayerId: playerId,
                targetPlayerName: playerName,
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return StaffTechniqueHubTheme.secondary;
      case 'NORMAL':
        return StaffTechniqueHubTheme.success;
      case 'FATIGUED':
        return StaffTechniqueHubTheme.warning;
      case 'OVERLOADED':
      case 'CRITICAL':
      case 'RECOVERY REQUIRED':
        return StaffTechniqueHubTheme.danger;
      default:
        return StaffTechniqueHubTheme.textSecondary;
    }
  }
}
