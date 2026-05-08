import '../models/player.dart';
import 'api_client.dart';

class PlayersService {
  final ApiClient _apiClient;

  PlayersService(this._apiClient);

  /// Récupère la liste de tous les joueurs actifs du club.
  Future<List<Player>> getPlayers() async {
    try {
      final response = await _apiClient.get('/players');
      final List<dynamic> data = response.data;
      return data.map((json) => Player.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des joueurs: $e');
    }
  }

  /// Récupère le profil complet d'un joueur par son identifiant unique.
  Future<Player> getPlayer(String id) async {
    try {
      final response = await _apiClient.get('/players/$id');
      return Player.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du joueur: $e');
    }
  }

  /// Crée un nouveau profil de joueur.
  Future<Player> createPlayer(Player player) async {
    try {
      final response = await _apiClient.post(
        '/players',
        data: player.toJson(),
      );
      return Player.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création du joueur: $e');
    }
  }

  /// Met à jour les informations personnelles ou sportives d'un joueur.
  Future<Player> updatePlayer(String id, Player player) async {
    try {
      final response = await _apiClient.patch(
        '/players/$id',
        data: player.toJson(),
      );
      return Player.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du joueur: $e');
    }
  }

  /// Supprime un joueur de la base de données (ou l'archive selon la logique backend).
  Future<void> deletePlayer(String id) async {
    try {
      await _apiClient.delete('/players/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du joueur: $e');
    }
  }
}
