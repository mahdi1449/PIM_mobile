import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/test_type.dart';
import '../services/api_client.dart';
import '../services/test_types_service.dart';

/// Fournit une instance de [TestTypesService] pour accéder au catalogue des types de tests.
final testTypesServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return TestTypesService(apiClient);
});

/// Provider qui récupère le catalogue des types de tests.
/// Le paramètre [activeOnly] (bool) permet de filtrer les tests désactivés.
final testTypesProvider =
    FutureProvider.autoDispose.family<List<TestType>, bool>((ref, activeOnly) async {
  final service = ref.read(testTypesServiceProvider);
  return service.getTestTypes(activeOnly: activeOnly);
});

/// Raccourci pour récupérer uniquement les types de tests actifs (utilisés dans les formulaires).
final activeTestTypesProvider = FutureProvider<List<TestType>>((ref) async {
  final service = ref.read(testTypesServiceProvider);
  return service.getTestTypes(activeOnly: true);
});

/// Provider qui récupère les détails d'un type de test spécifique (seuils, formule de normalisation).
final testTypeProvider =
    FutureProvider.family<TestType, String>((ref, testTypeId) async {
  final service = ref.read(testTypesServiceProvider);
  return service.getTestType(testTypeId);
});

/// Provider de formulaire gérant la création, la modification et la suppression de types de tests.
final testTypeFormProvider =
    StateNotifierProvider<TestTypeFormNotifier, AsyncValue<TestType?>>((ref) {
  final service = ref.read(testTypesServiceProvider);
  return TestTypeFormNotifier(service, ref);
});

/// Notifier qui gère les mutations du catalogue de tests.
/// Invalide [testTypesProvider] et [activeTestTypesProvider] après chaque opération.
class TestTypeFormNotifier extends StateNotifier<AsyncValue<TestType?>> {
  final TestTypesService _service;
  final Ref _ref;

  TestTypeFormNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  /// Crée un nouveau type de test dans le catalogue et rafraîchit les listes associées.
  Future<TestType?> createTestType(TestType testType) async {
    state = const AsyncValue.loading();
    try {
      final createdTestType = await _service.createTestType(testType);
      state = AsyncValue.data(createdTestType);
      _ref.invalidate(testTypesProvider);
      _ref.invalidate(activeTestTypesProvider);
      return createdTestType;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Met à jour un type de test existant (ex: modifier les seuils min/max de normalisation).
  Future<TestType?> updateTestType(String id, TestType testType) async {
    state = const AsyncValue.loading();
    try {
      final updatedTestType = await _service.updateTestType(id, testType);
      state = AsyncValue.data(updatedTestType);
      _ref.invalidate(testTypesProvider);
      _ref.invalidate(activeTestTypesProvider);
      _ref.invalidate(testTypeProvider(id));
      return updatedTestType;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Supprime un type de test du catalogue et nettoie les deux caches associés.
  Future<bool> deleteTestType(String id) async {
    try {
      await _service.deleteTestType(id);
      _ref.invalidate(testTypesProvider);
      _ref.invalidate(activeTestTypesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}
