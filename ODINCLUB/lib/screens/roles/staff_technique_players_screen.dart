import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sports_performance/cognitive_lab/screens/cognitive_dashboard_screen.dart';
import '../../sports_performance/models/player.dart';
import '../../sports_performance/providers/players_provider.dart';
import '../../sports_performance/screens/players/create_player_screen.dart';
import '../../ui/shell/app_shell.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniquePlayersScreen extends ConsumerStatefulWidget {
  const StaffTechniquePlayersScreen({super.key});

  @override
  ConsumerState<StaffTechniquePlayersScreen> createState() =>
      _StaffTechniquePlayersScreenState();
}

class _StaffTechniquePlayersScreenState
    extends ConsumerState<StaffTechniquePlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePlayerScreen()),
          );
        },
        backgroundColor: StaffTechniqueHubTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nouveau joueur'),
      ),
      body: StaffTechniquePageBackground(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 96 + bottomInset),
        child: playersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: StaffTechniqueEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Chargement impossible',
              subtitle: error.toString(),
            ),
          ),
          data: (players) {
            final filtered = players.where((player) {
              final haystack = '${player.fullName} ${player.position}'
                  .toLowerCase();
              return haystack.contains(_searchQuery.toLowerCase());
            }).toList();
            final averageAge = players.isEmpty
                ? 0
                : players.map((player) => player.age).reduce((a, b) => a + b) /
                      players.length;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(playersProvider),
              child: ListView(
                children: [
                  StaffTechniqueHeroCard(
                    eyebrow: 'Squad Desk',
                    title: 'Effectif du club',
                    subtitle:
                        'Visualise rapidement les profils, les postes et les portes d\'entree vers l\'analyse individuelle.',
                    icon: Icons.groups_rounded,
                    trailing: const StaffTechniqueStatusChip(
                      label: 'Updated today',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: StaffTechniqueMetricCard(
                          label: 'Joueurs',
                          value: '${players.length}',
                          icon: Icons.people_alt_rounded,
                          caption: 'effectif total',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StaffTechniqueMetricCard(
                          label: 'Age moyen',
                          value: players.isEmpty
                              ? '-'
                              : averageAge.toStringAsFixed(1),
                          icon: Icons.insights_rounded,
                          accent: StaffTechniqueHubTheme.secondary,
                          caption: 'projection groupe',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  StaffTechniqueSearchField(
                    controller: _searchController,
                    hintText: 'Chercher un joueur par nom ou poste...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 22),
                  const StaffTechniqueSectionTitle(title: 'Top Targets'),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const StaffTechniqueEmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Aucun joueur trouve',
                      subtitle:
                          'Essaie une autre recherche ou ajoute un nouveau profil.',
                    )
                  else
                    ...filtered.map(_buildPlayerCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: player.fullName,
        subtitle:
            '${player.age} ans  •  ${player.position}  •  #${player.jerseyNumber ?? '-'}',
        icon: Icons.person_outline_rounded,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StaffTechniqueStatusChip(
              label: player.strongFoot,
              color: StaffTechniqueHubTheme.secondary,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Modifier',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePlayerScreen(playerToEdit: player),
                  ),
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: StaffTechniqueHubTheme.primary,
              ),
            ),
          ],
        ),
        onTap: () {
          final session = AppShellScope.of(context)?.session;
          if (session == null) {
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CognitiveDashboardScreen(
                session: session,
                targetPlayerId: player.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
