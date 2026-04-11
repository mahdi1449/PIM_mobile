import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sports_performance/models/test_type.dart';
import '../../sports_performance/providers/test_types_provider.dart';
import '../../sports_performance/screens/test_types/create_test_type_screen.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueTestsHubScreen extends ConsumerStatefulWidget {
  const StaffTechniqueTestsHubScreen({super.key});

  @override
  ConsumerState<StaffTechniqueTestsHubScreen> createState() =>
      _StaffTechniqueTestsHubScreenState();
}

class _StaffTechniqueTestsHubScreenState
    extends ConsumerState<StaffTechniqueTestsHubScreen> {
  bool _showInactive = true;

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(testTypesProvider(!_showInactive));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTestTypeScreen()),
          );
        },
        backgroundColor: StaffTechniqueHubTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Nouvelle metrique'),
      ),
      body: StaffTechniquePageBackground(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 96 + bottomInset),
        child: testsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: StaffTechniqueEmptyState(
              icon: Icons.monitor_heart_outlined,
              title: 'Metrics indisponibles',
              subtitle: error.toString(),
            ),
          ),
          data: (types) {
            final activeCount = types.where((type) => type.isActive).length;

            return ListView(
              children: [
                StaffTechniqueHeroCard(
                  eyebrow: 'Evaluation Metrics',
                  title: 'Bibliotheque des tests',
                  subtitle:
                      'Maintiens les indicateurs physiques, techniques et mentaux sur une base claire et moderne.',
                  icon: Icons.monitor_heart_rounded,
                  trailing: IconButton(
                    tooltip: _showInactive
                        ? 'Masquer les inactifs'
                        : 'Afficher les inactifs',
                    onPressed: () {
                      setState(() => _showInactive = !_showInactive);
                    },
                    icon: Icon(
                      _showInactive
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Actives',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline_rounded,
                        accent: StaffTechniqueHubTheme.success,
                        caption: 'metriques operationnelles',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StaffTechniqueMetricCard(
                        label: 'Total',
                        value: '${types.length}',
                        icon: Icons.tune_rounded,
                        accent: StaffTechniqueHubTheme.secondary,
                        caption: _showInactive
                            ? 'avec inactives'
                            : 'liste visible',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const StaffTechniqueSectionTitle(title: 'Metrics Catalog'),
                const SizedBox(height: 12),
                if (types.isEmpty)
                  const StaffTechniqueEmptyState(
                    icon: Icons.rule_folder_outlined,
                    title: 'Aucune metrique',
                    subtitle:
                        'Commence par creer une metrique pour cadrer les evaluations.',
                  )
                else
                  ...types.map(_buildMetricCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(TestType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: type.name,
        subtitle:
            '${type.categoryLabel}  •  ${type.unit}  •  ${type.scoringMethodLabel}',
        icon: type.betterIsHigher
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        trailing: StaffTechniqueStatusChip(
          label: type.isActive ? 'Active' : 'Inactive',
          color: type.isActive
              ? StaffTechniqueHubTheme.success
              : StaffTechniqueHubTheme.textSecondary,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateTestTypeScreen(testTypeToEdit: type),
            ),
          );
        },
      ),
    );
  }
}
