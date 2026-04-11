import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sports_performance/models/exercise.dart';
import '../../sports_performance/providers/exercises_provider.dart';
import '../../sports_performance/screens/exercises/generator_form.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueExercisesHubScreen extends ConsumerStatefulWidget {
  const StaffTechniqueExercisesHubScreen({super.key});

  @override
  ConsumerState<StaffTechniqueExercisesHubScreen> createState() =>
      _StaffTechniqueExercisesHubScreenState();
}

class _StaffTechniqueExercisesHubScreenState
    extends ConsumerState<StaffTechniqueExercisesHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneratorForm()),
          );
        },
        backgroundColor: StaffTechniqueHubTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Generer un exercice'),
      ),
      body: StaffTechniquePageBackground(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 96 + bottomInset),
        child: exercisesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: StaffTechniqueEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Bibliotheque indisponible',
              subtitle: error.toString(),
            ),
          ),
          data: (exercises) {
            final filtered = exercises.where((exercise) {
              final haystack =
                  '${exercise.name} ${exercise.category.label} ${exercise.intensity.label}'
                      .toLowerCase();
              return haystack.contains(_query.toLowerCase());
            }).toList();
            final aiCount = exercises
                .where((exercise) => exercise.aiGenerated)
                .length;

            return ListView(
              children: [
                StaffTechniqueHeroCard(
                  eyebrow: 'Exercise Library',
                  title: 'Catalogue terrain',
                  subtitle:
                      'Centralise les ateliers, trie par intensite et fais remonter rapidement les contenus generes par IA.',
                  icon: Icons.menu_book_rounded,
                  trailing: StaffTechniqueStatusChip(
                    label: '$aiCount IA',
                    color: StaffTechniqueHubTheme.secondary,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Exercices',
                        value: '${exercises.length}',
                        icon: Icons.fitness_center_rounded,
                        caption: 'catalogue total',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Filtres',
                        value: '${filtered.length}',
                        icon: Icons.tune_rounded,
                        accent: StaffTechniqueHubTheme.secondary,
                        caption: 'selection visible',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                StaffTechniqueSearchField(
                  controller: _searchController,
                  hintText:
                      'Rechercher un exercice, une categorie ou une intensite...',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 22),
                const StaffTechniqueSectionTitle(title: 'Exercise Feed'),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const StaffTechniqueEmptyState(
                    icon: Icons.sports_gymnastics_outlined,
                    title: 'Aucun exercice visible',
                    subtitle:
                        'Modifie la recherche ou genere un nouveau contenu IA.',
                  )
                else
                  ...filtered.map(_buildExerciseCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final positions = exercise.targetPositions
        .map((item) => item.value)
        .join('/');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: exercise.name,
        subtitle:
            '${exercise.category.label}  •  ${exercise.intensity.label}  •  ${exercise.duration.toStringAsFixed(0)} min${positions.isEmpty ? '' : '  •  $positions'}',
        icon: Icons.sports_rounded,
        trailing: exercise.aiGenerated
            ? const StaffTechniqueStatusChip(
                label: 'AI',
                color: StaffTechniqueHubTheme.secondary,
              )
            : StaffTechniqueStatusChip(
                label: 'D${exercise.difficulty}',
                color: StaffTechniqueHubTheme.primary,
              ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              final steps = exercise.technicalData?.steps ?? const <String>[];
              return SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: StaffTechniqueHubTheme.cardDecoration(),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: StaffTechniqueHubTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.technicalData?.description ??
                              'Aucune description detaillee disponible.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: StaffTechniqueHubTheme.textSecondary,
                                height: 1.45,
                              ),
                        ),
                        if (steps.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...steps.map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• $step',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
