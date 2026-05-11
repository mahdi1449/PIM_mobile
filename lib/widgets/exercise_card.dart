import 'package:flutter/material.dart';
import '../sports_performance/models/exercise.dart';
import '../sports_performance/theme/sp_colors.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    this.onTap,
    this.onAdd,
  }) : super(key: key);

  Color _getCategoryColor(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.physical:
        return const Color(0xFFFF3B30); // Neon Red
      case ExerciseCategory.technical:
        return const Color(0xFF00C7BE); // Neon Cyan
      case ExerciseCategory.tactical:
        return const Color(0xFF34C759); // Neon Green
      case ExerciseCategory.cognitive:
        return const Color(0xFFAF52DE); // Neon Purple
    }
  }

  IconData _getCategoryIcon(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.physical:
        return Icons.fitness_center_rounded;
      case ExerciseCategory.technical:
        return Icons.sports_soccer_rounded;
      case ExerciseCategory.tactical:
        return Icons.map_outlined;
      case ExerciseCategory.cognitive:
        return Icons.psychology_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAi = exercise.aiGenerated;
    final catColor = _getCategoryColor(exercise.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SPColors.backgroundSecondary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAi ? const Color(0xFFAF52DE).withOpacity(0.4) : SPColors.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isAi
            ? [
                BoxShadow(
                  color: const Color(0xFFAF52DE).withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: -5,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with AI Badge and Image Placeholder
                Stack(
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: exercise.imageUrl != null && exercise.imageUrl!.isNotEmpty
                          ? Image.network(
                              exercise.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: catColor.withOpacity(0.5),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(catColor),
                            )
                          : _buildImagePlaceholder(catColor),
                    ),
                    
                    // Top Right - AI Badge
                    if (isAi)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFAF52DE), Color(0xFF5E5CE6)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAF52DE).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'AI POWERED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Bottom Left - Duration Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              exercise.duration < 1
                                  ? '${(exercise.duration * 60).toInt()} sec'
                                  : '${exercise.duration % 1 == 0 ? exercise.duration.toInt() : exercise.duration} min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onAdd != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: SPColors.primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: onAdd,
                                  icon: const Icon(Icons.add),
                                  color: SPColors.primaryBlue,
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  iconSize: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Metrics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Difficulty Stars
                          Row(
                            children: List.generate(5, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  index < exercise.difficulty ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: index < exercise.difficulty ? const Color(0xFFFFD60A) : SPColors.textTertiary.withOpacity(0.3),
                                  size: 16,
                                ),
                              );
                            }),
                          ),
                          
                          // Position Tags
                          _buildPositionIcons(exercise.targetPositions),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Intensity Bar
                      _buildIntensityBar(exercise.intensity),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityBar(IntensityLevel intensity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'INTENSITÉ',
              style: TextStyle(
                color: SPColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              intensity.label.toUpperCase(),
              style: TextStyle(
                color: intensity.color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: SPColors.backgroundTertiary,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: intensity == IntensityLevel.low ? 0.3 : (intensity == IntensityLevel.medium ? 0.6 : 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: intensity.color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: intensity.color.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionIcons(List<PitchPosition> positions) {
    if (positions.isEmpty) return const SizedBox.shrink();
    
    // Only show up to 3 positions to avoid overflow
    final displayPositions = positions.take(3).toList();
    final hasMore = positions.length > 3;

    return Row(
      children: [
        ...displayPositions.map((p) {
          return Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SPColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: SPColors.borderPrimary.withOpacity(0.5)),
            ),
            child: Text(
              p.value,
              style: const TextStyle(
                color: SPColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        if (hasMore)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: SPColors.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '+',
              style: TextStyle(
                color: SPColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder(Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor.withOpacity(0.15),
            SPColors.backgroundSecondary.withOpacity(0.8),
            SPColors.backgroundPrimary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: catColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(
                _getCategoryIcon(exercise.category),
                size: 36,
                color: catColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              exercise.category.label.toUpperCase(),
              style: TextStyle(
                color: catColor.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
