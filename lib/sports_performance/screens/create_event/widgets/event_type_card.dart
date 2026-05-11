import 'package:flutter/material.dart';
import '../../../theme/sp_colors.dart';
import '../../../theme/sp_typography.dart';
import '../../../models/event.dart';

class EventTypeCard extends StatelessWidget {
  final EventType type;
  final bool isSelected;
  final VoidCallback onTap;

  const EventTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: isSelected 
                ? SPColors.primaryBlue.withOpacity(0.15) 
                : SPColors.backgroundSecondary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? SPColors.primaryBlue.withOpacity(0.8) : SPColors.borderPrimary.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: SPColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(isSelected),
                color: isSelected ? SPColors.primaryBlue : SPColors.textTertiary,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                _getLabel(),
                style: SPTypography.bodyMedium.copyWith(
                  color: isSelected ? SPColors.primaryBlue : SPColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(bool selected) {
    switch (type) {
      case EventType.testSession:
        return selected ? Icons.speed : Icons.speed_outlined;
      case EventType.match:
        return selected ? Icons.sports_soccer : Icons.sports_soccer_outlined;
      case EventType.evaluation:
        return selected ? Icons.assignment : Icons.assignment_outlined;
      case EventType.detection:
        return selected ? Icons.visibility : Icons.visibility_outlined;
      case EventType.medical:
        return selected ? Icons.medical_services : Icons.medical_services_outlined;
      case EventType.recovery:
        return selected ? Icons.self_improvement : Icons.self_improvement_outlined;
      case EventType.aiAnalysis:
        return selected ? Icons.psychology : Icons.psychology_outlined;
    }
  }

  String _getLabel() {
    switch (type) {
      case EventType.testSession:
        return 'Session de Test';
      case EventType.match:
        return 'Match';
      case EventType.evaluation:
        return 'Évaluation';
      case EventType.detection:
        return 'Détection';
      case EventType.medical:
        return 'Médical';
      case EventType.recovery:
        return 'Récupération';
      case EventType.aiAnalysis:
        return 'Analyse IA';
    }
  }
}

