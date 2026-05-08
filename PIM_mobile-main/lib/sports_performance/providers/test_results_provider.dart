import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/test_result.dart';
import '../services/api_client.dart';
import '../services/test_results_service.dart';

/// Fournit une instance de [TestResultsService] pour les providers de résultats.
final testResultsServiceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return TestResultsService(apiClient);
});

/// Provider récupérant les résultats de tests d'un participant ([eventPlayerId]).
/// Cache invalidé après chaque mutation.
final testResultsProvider =
    FutureProvider.family<List<TestResult>, String>((ref, eventPlayerId) async {
  final service = ref.read(testResultsServiceProvider);
  return service.getTestResults(eventPlayerId);
});

/// Provider de formulaire gérant l'enregistrement et la modification des résultats de tests.
final testResultFormProvider =
    StateNotifierProvider<TestResultFormNotifier, AsyncValue<TestResult?>>((ref) {
  final service = ref.read(testResultsServiceProvider);
  return TestResultFormNotifier(service, ref);
});

/// Notifier gérant la création, mise à jour et suppression des résultats de tests.
class TestResultFormNotifier extends StateNotifier<AsyncValue<TestResult?>> {
  final TestResultsService _service;
  final Ref _ref;

  TestResultFormNotifier(this._service, this._ref)
      : super(const AsyncValue.data(null));

  /// Soumet une valeur brute mesurée sur le terrain et force le rechargement du cache.
  Future<TestResult?> createTestResult({
    required String eventPlayerId,
    required String testTypeId,
    required double rawValue,
    String? notes,
    String? recordedBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      final testResult = await _service.createTestResult(
        eventPlayerId,
        testTypeId,
        rawValue,
        notes: notes,
        recordedBy: recordedBy,
      );
      state = AsyncValue.data(testResult);
      _ref.invalidate(testResultsProvider(eventPlayerId));
      return testResult;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Corrige une valeur brute enregistrée et invalide le cache des résultats.
  Future<TestResult?> updateTestResult({
    required String id,
    required String eventPlayerId,
    required double rawValue,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final testResult = await _service.updateTestResult(
        id,
        rawValue,
        notes: notes,
      );
      state = AsyncValue.data(testResult);
      _ref.invalidate(testResultsProvider(eventPlayerId));
      return testResult;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /// Supprime un résultat de test et rafraîchit la liste du joueur.
  Future<bool> deleteTestResult(String id, String eventPlayerId) async {
    try {
      await _service.deleteTestResult(id);
      _ref.invalidate(testResultsProvider(eventPlayerId));
      return true;
    } catch (e) {
      return false;
    }
  }
}


