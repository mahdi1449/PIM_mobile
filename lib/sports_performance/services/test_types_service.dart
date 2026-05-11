import '../models/test_type.dart';
import 'api_client.dart';

class TestTypesService {
  final ApiClient _apiClient;

  TestTypesService(this._apiClient);

  /// Récupère le catalogue des types de tests disponibles.
  /// Gère différents formats de réponse JSON du backend.
  /// [activeOnly] : si `true`, ne retourne que les tests actifs (utilisables dans un événement).
  Future<List<TestType>> getTestTypes({bool activeOnly = false}) async {
    try {
      final response = await _apiClient.get(
        '/test-types',
        queryParameters: activeOnly ? {'activeOnly': 'true'} : null,
      );
      
      dynamic rawData = response.data;
      List<dynamic> listData = [];
      
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map) {
        if (rawData['data'] != null) {
          if (rawData['data'] is List) {
            listData = rawData['data'];
          } else if (rawData['data'] is Map && rawData['data']['testTypes'] is List) {
            listData = rawData['data']['testTypes'];
          }
        } else if (rawData['testTypes'] is List) {
          listData = rawData['testTypes'];
        }
      }
      
      return listData.map((json) => TestType.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des types de tests: $e');
    }
  }

  /// Récupère les détails d'un type de test par son ID (formule de normalisation, seuils).
  Future<TestType> getTestType(String id) async {
    try {
      final response = await _apiClient.get('/test-types/$id');
      return TestType.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du type de test: $e');
    }
  }

  /// Crée un nouveau type de test dans le catalogue.
  Future<TestType> createTestType(TestType testType) async {
    try {
      final response = await _apiClient.post(
        '/test-types',
        data: testType.toJson(),
      );
      return TestType.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création du type de test: $e');
    }
  }

  /// Met à jour un type de test existant (ex: modifier les seuils de normalisation).
  Future<TestType> updateTestType(String id, TestType testType) async {
    try {
      final response = await _apiClient.patch(
        '/test-types/$id',
        data: testType.toJson(),
      );
      return TestType.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du type de test: $e');
    }
  }

  /// Supprime un type de test du catalogue.
  Future<void> deleteTestType(String id) async {
    try {
      await _apiClient.delete('/test-types/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du type de test: $e');
    }
  }
}
