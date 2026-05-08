import '../models/cognitive_session.dart';
import '../../services/api_client.dart';

/// Service Flutter d'accès aux données du Laboratoire Cognitif.
/// Permet de soumettre de nouvelles sessions et de consulter l'état mental des joueurs.
class CognitiveLabService {
  final ApiClient _apiClient;

  CognitiveLabService(this._apiClient);

  /// Soumet une nouvelle session cognitive pour un joueur.
  /// Les données comprennent les scores de réaction, de mémoire et de concentration mesurés lors du test.
  Future<CognitiveSession> createSession(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/cognitive-lab/sessions', data: data);
      return CognitiveSession.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création de la session cognitive: $e');
    }
  }

  /// Récupère le tableau de bord cognitif d'un joueur (historique, score de base, tendance).
  Future<Map<String, dynamic>> getDashboard(String playerId) async {
    try {
      final response = await _apiClient.get('/cognitive-lab/dashboard/$playerId');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du dashboard cognitif: $e');
    }
  }

  /// Récupère une vue d'ensemble de la fatigue cognitive de tout le groupe (équipe).
  /// Utilisé par les coachs pour détecter les joueurs à risque avant un match.
  Future<Map<String, dynamic>> getSquadOverview() async {
    try {
      final response = await _apiClient.get('/cognitive-lab/squad-today');
      return response.data;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du squad overview: $e');
    }
  }
}
