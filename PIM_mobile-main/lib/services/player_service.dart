import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/player_model.dart';
import 'api_config.dart';

/// Service d'accès aux données des joueurs via l'API REST.
/// Utilisé par les modules médicaux pour lier l'analyse IA au profil correct du joueur.
class PlayerService {
  /// Récupère la liste de tous les joueurs enregistrés dans le club.
  /// Gère deux formats de réponse : tableau direct ou objet avec clé `data`.
  Future<List<PlayerModel>> fetchPlayers() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/players');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load players');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map((item) => PlayerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((item) => PlayerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return const [];
  }

  /// Récupère le profil complet d'un joueur par son identifiant unique.
  Future<PlayerModel> fetchPlayer(String playerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/players/$playerId');
    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load player');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return PlayerModel.fromJson(decoded);
    }

    throw Exception('Unexpected player response format');
  }

  /// Efface le statut médical actif d'un joueur (ex: après validation du retour à l'entraînement).
  /// Retourne le profil mis à jour avec le nouveau statut.
  Future<PlayerModel> clearMedical(String playerId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/players/$playerId/clear-medical',
    );
    final response = await http.post(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to clear medical status: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return PlayerModel.fromJson(decoded);
    }

    throw Exception('Unexpected clear medical response format');
  }
}
