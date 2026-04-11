import 'package:flutter/material.dart';

import '../../season_planning/models/season_plan.dart';
import '../../season_planning/screens/season_dashboard_screen.dart';
import '../../season_planning/services/season_plan_service.dart';
import '../../ui/theme/staff_technique_hub.dart';

class StaffTechniqueSeasonHubScreen extends StatefulWidget {
  const StaffTechniqueSeasonHubScreen({super.key});

  @override
  State<StaffTechniqueSeasonHubScreen> createState() =>
      _StaffTechniqueSeasonHubScreenState();
}

class _StaffTechniqueSeasonHubScreenState
    extends State<StaffTechniqueSeasonHubScreen> {
  List<SeasonPlan> _plans = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await SeasonPlanService.getPlans();
      if (!mounted) {
        return;
      }
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement saison: $error')),
      );
    }
  }

  Future<void> _createSeason() async {
    final now = DateTime.now();
    final titleController = TextEditingController();
    final yearController = TextEditingController(
      text: '${now.year}-${now.year + 1}',
    );
    final objectiveController = TextEditingController();
    final gameModelController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle saison'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Equipe / groupe'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Saison'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: objectiveController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Objectif principal',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gameModelController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Modele de jeu'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Creer'),
          ),
        ],
      ),
    );

    if (shouldCreate != true || !mounted) {
      return;
    }

    final year = yearController.text.trim();
    final firstYear = int.tryParse(year.split('-').first.trim()) ?? now.year;
    final secondYear = year.split('-').length > 1
        ? int.tryParse(year.split('-')[1].trim()) ?? firstYear + 1
        : firstYear + 1;

    final plan = SeasonPlan(
      title: titleController.text.trim(),
      year: year,
      startDate: DateTime(firstYear, 7, 1),
      endDate: DateTime(secondYear, 6, 30),
      collectivePreparation: CollectivePreparation(
        primaryObjective: objectiveController.text.trim(),
        gameModel: gameModelController.text.trim(),
      ),
    );

    try {
      await SeasonPlanService.createPlan(plan);
      await _loadPlans();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saison creee.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur creation saison: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSeason,
        backgroundColor: StaffTechniqueHubTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle saison'),
      ),
      body: StaffTechniquePageBackground(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 96 + bottomInset),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPlans,
                child: ListView(
                  children: [
                    StaffTechniqueHeroCard(
                      eyebrow: 'Season Planning',
                      title: 'Roadmap de la saison',
                      subtitle:
                          'Cadre les objectifs, ouvre tes saisons et suis les blocs de charge sur le long terme.',
                      icon: Icons.route_rounded,
                      trailing: StaffTechniqueStatusChip(
                        label: '${_plans.length} saisons',
                        color: StaffTechniqueHubTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: StaffTechniqueMetricCard(
                            label: 'Plans',
                            value: '${_plans.length}',
                            icon: Icons.layers_outlined,
                            caption: 'saisons configurees',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StaffTechniqueMetricCard(
                            label: 'Blocs',
                            value:
                                '${_plans.fold<int>(0, (sum, plan) => sum + plan.macroCycles.length)}',
                            icon: Icons.timeline_rounded,
                            accent: StaffTechniqueHubTheme.secondary,
                            caption: 'macro-cycles connus',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const StaffTechniqueSectionTitle(title: 'Season Boards'),
                    const SizedBox(height: 12),
                    if (_plans.isEmpty)
                      const StaffTechniqueEmptyState(
                        icon: Icons.calendar_month_outlined,
                        title: 'Aucune saison planifiee',
                        subtitle:
                            'Cree ta premiere saison pour lancer la planification collective.',
                      )
                    else
                      ..._plans.map(_buildPlanCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanCard(SeasonPlan plan) {
    final objective = plan.collectivePreparation.primaryObjective.trim();
    final subtitle =
        '${plan.year}  •  ${plan.macroCycles.length} blocs  •  ${objective.isEmpty ? 'objectif a definir' : objective}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StaffTechniqueActionCard(
        title: plan.title,
        subtitle: subtitle,
        icon: Icons.track_changes_rounded,
        trailing: const Icon(
          Icons.arrow_forward_rounded,
          color: StaffTechniqueHubTheme.primary,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeasonDashboardScreen(plan: plan),
            ),
          );
          if (mounted) {
            _loadPlans();
          }
        },
      ),
    );
  }
}
