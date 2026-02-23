import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/exercises_provider.dart';
import '../../theme/sp_colors.dart';
import '../../theme/sp_typography.dart';
import '../../../widgets/exercise_card.dart';
import 'generator_form.dart';
import 'stopwatch_performance_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? _selectedCategory;
  bool _aiOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories => [
        'All',
        'Physical',
        'Technical',
        'Tactical',
        'Cognitive',
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use filteredExercisesProvider or exercisesProvider and filter locally
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      backgroundColor: SPColors.backgroundPrimary,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'EXERCISE LIBRARY',
              style: SPTypography.overline.copyWith(
                color: SPColors.primaryBlue,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Odin Intelligent ERP',
              style: SPTypography.caption.copyWith(
                color: SPColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and AI Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un exercice...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildAiToggle(),
              ],
            ),
          ),

          // Categories Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = (_selectedCategory == null && category == 'All') ||
                      (_selectedCategory == category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category == 'All' ? null : category;
                        });
                      },
                      selectedColor: SPColors.badgeTechnical.withOpacity(0.3),
                      backgroundColor: SPColors.backgroundSecondary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : SPColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? SPColors.badgeTechnical : SPColors.borderPrimary,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),
          ),

          // Exercises List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = exercises.where((e) {
                  final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == null || e.category.value == _selectedCategory;
                  final matchesAi = !_aiOnly || e.aiGenerated;
                  return matchesSearch && matchesCategory && matchesAi;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ExerciseCard(
                      exercise: filtered[index],
                      onTap: () => _showExerciseDetails(context, filtered[index]),
                      onAdd: () {
                        // Add to session
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneratorForm()),
          );
        },
        backgroundColor: SPColors.badgeTechnical,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildAiToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _aiOnly ? SPColors.badgeTechnical.withOpacity(0.1) : SPColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _aiOnly ? SPColors.badgeTechnical : SPColors.borderPrimary,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _aiOnly = !_aiOnly),
        child: Row(
          children: [
             Icon(
              Icons.auto_awesome,
              size: 16,
              color: _aiOnly ? Colors.white : SPColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'AI ONLY',
              style: TextStyle(
                color: _aiOnly ? Colors.white : SPColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: SPColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Aucun exercice trouvé',
            style: SPTypography.bodyLarge.copyWith(color: SPColors.textSecondary),
          ),
          if (_aiOnly) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GeneratorForm()),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Générer avec l\'IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SPColors.badgeTechnical,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: SPColors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: SPColors.primaryBlue.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: SPColors.primaryBlue, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        Text(
                          'VISUAL DRILL GUIDE',
                          style: SPTypography.label.copyWith(
                            color: SPColors.primaryBlue,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MODE GIF ANIMÉ',
                          style: SPTypography.caption.copyWith(
                            color: SPColors.textTertiary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: SPColors.primaryBlue),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Hero GIF Section with Overlays
                    if (exercise.imageUrl != null)
                      Stack(
                        children: [
                          Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: SPColors.primaryBlue.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: SPColors.primaryBlue.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Image.network(
                                exercise.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Overlay Live View
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LOOPING LIVE VIEW',
                                  style: SPTypography.caption.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Replay Indicator
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 80),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SPColors.primaryBlue.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: SPColors.primaryBlue.withOpacity(0.5)),
                              ),
                              child: const Icon(Icons.replay_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                          // Fullscreen icon
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    // Title and Metadata
                    Text(
                      exercise.name,
                      style: SPTypography.h2.copyWith(color: Colors.white, fontSize: 24),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSmallMetric(Icons.timer_outlined, '${exercise.duration.toInt()} Mins'),
                        const SizedBox(width: 16),
                        _buildSmallMetric(Icons.bolt, exercise.difficulty > 3 ? 'Pro Level' : 'Beginner'),
                        const SizedBox(width: 16),
                        _buildSmallMetric(Icons.straighten_rounded, '${exercise.technicalData?.equipment.length ?? 0} Items'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Steps Section (Card Style)
                    Text(
                      'DÉMARCHE DE L\'EXERCICE',
                      style: SPTypography.label.copyWith(
                        color: SPColors.primaryBlue,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...exercise.technicalData!.steps.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final isFirst = index == 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isFirst ? SPColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFirst ? SPColors.primaryBlue.withOpacity(0.3) : SPColors.borderPrimary.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isFirst ? SPColors.primaryBlue : SPColors.backgroundTertiary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      color: isFirst ? Colors.white : SPColors.textTertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ÉTAPE $index'.toUpperCase(),
                                      style: TextStyle(
                                        color: isFirst ? SPColors.primaryBlue : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.value,
                                      style: SPTypography.bodySmall.copyWith(
                                        color: isFirst ? Colors.white : SPColors.textSecondary,
                                        height: 1.5,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    // Equipment Section
                    Text(
                      'MATÉRIEL REQUIS',
                      style: SPTypography.caption.copyWith(
                        color: SPColors.textTertiary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (exercise.technicalData?.equipment ?? []).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: SPColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: SPColors.borderPrimary),
                          ),
                          child: Text(
                            item.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              // Premium Bottom Action Bar (Sticky)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: SPColors.backgroundPrimary,
                  border: Border(top: BorderSide(color: SPColors.primaryBlue.withOpacity(0.1))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Nav Icons
                    _buildNavIcon(Icons.home_outlined, 'Accueil', false),
                    const SizedBox(width: 20),
                    _buildNavIcon(Icons.track_changes_rounded, 'Drills', true),
                    const SizedBox(width: 20),
                    _buildNavIcon(Icons.bar_chart_rounded, 'Stats', false),
                    const SizedBox(width: 24),
                    // Main Action
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: SPColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: SPColors.primaryBlue.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StopwatchPerformanceScreen(exercise: exercise),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'DÉMARRER',
                                  style: SPTypography.label.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? SPColors.primaryBlue : SPColors.textTertiary, size: 24),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isActive ? SPColors.primaryBlue : SPColors.textTertiary,
            fontSize: 7,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: SPColors.primaryBlue, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: SPTypography.caption.copyWith(color: SPColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
