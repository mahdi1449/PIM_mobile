import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../services/api_client.dart';
import '../services/exercises_service.dart';

/// Fournit une instance de [ExercisesService] à l'ensemble des providers d'exercices.
final exercisesServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return ExercisesService(apiClient);
});

/// Provider qui récupère la liste complète des exercices disponibles.
/// `autoDispose` libère la mémoire quand l'écran est quitté.
final exercisesProvider = FutureProvider.autoDispose<List<Exercise>>((ref) async {
  final service = ref.read(exercisesServiceProvider);
  return service.getExercises();
});

/// Provider filtré pour récupérer les exercices par catégorie ou par origine (IA vs Manuel).
final filteredExercisesProvider = FutureProvider.autoDispose.family<List<Exercise>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.read(exercisesServiceProvider);
  return service.getExercises(
    category: filters['category'],
    aiGenerated: filters['aiGenerated'],
  );
});

/// Provider qui charge les analyses prédictives de l'IA pour adapter l'entraînement d'un joueur.
final playerInsightsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, playerId) async {
  final service = ref.read(exercisesServiceProvider);
  return service.getPlayerInsights(playerId);
});

/// Provider d'état gérant la génération à la demande d'un exercice personnalisé par l'IA.
final aiDrillGenerationProvider = StateNotifierProvider<AiDrillGenerationNotifier, AsyncValue<Exercise?>>((ref) {
  final service = ref.read(exercisesServiceProvider);
  return AiDrillGenerationNotifier(service, ref);
});

/// Notifier qui envoie le contexte d'entraînement à l'IA et retourne le drill généré.
/// Invalide [exercisesProvider] pour que la liste se mette à jour après la génération.
class AiDrillGenerationNotifier extends StateNotifier<AsyncValue<Exercise?>> {
  final ExercisesService _service;
  final Ref _ref;

  AiDrillGenerationNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  /// Lance la génération d'un drill IA basé sur le contexte fourni (ex: lacunes du joueur).
  Future<Exercise?> generateDrill(Map<String, dynamic> context) async {
    state = const AsyncValue.loading();
    try {
      final drill = await _service.generateAiDrill(context);
      state = AsyncValue.data(drill);
      _ref.invalidate(exercisesProvider);
      return drill;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}
