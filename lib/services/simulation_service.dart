import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/player_model.dart';
import '../models/simulation_result_model.dart';
import '../models/simulation_start_model.dart';
import 'api_config.dart';

/// Service de simulation de match via l'API backend.
/// Orchestre le cycle complet : sélection des joueurs disponibles,
/// démarrage du match simulé et récupération des résultats finaux.
class SimulationService {
  /// Récupère la liste des joueurs disponibles pour être inclus dans la simulation.
  /// Gère deux formats de réponse JSON (tableau direct ou wrapper `data`).
  Future<List<PlayerModel>> fetchAvailablePlayers() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/available-players');
    final response = await http.get(url);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Available players failed: ${response.statusCode} ${response.body}',
      );
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

  /// Démarre une nouvelle simulation de match.
  /// Les [playerIds] optionnels permettent de sélectionner une équipe spécifique.
  /// Retourne un [SimulationStartModel] contenant l'ID du match et la configuration initiale.
  Future<SimulationStartModel> startMatch({List<String>? playerIds}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/start');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: playerIds == null ? null : jsonEncode({'playerIds': playerIds}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Simulation start failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return SimulationStartModel.fromJson(decoded);
    }

    throw Exception('Simulation start returned invalid payload');
  }

  /// Termine un match simulé et récupère les résultats de performance par joueur.
  /// Les [stats] optionnelles permettent d'injecter des données supplémentaires au moteur d'analyse.
  Future<List<SimulationResultModel>> endMatch(
    String matchId, {
    Map<String, dynamic>? stats,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/simulation/end/$matchId');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: stats == null ? null : jsonEncode({'stats': stats}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Simulation end failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (item) =>
                SimulationResultModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map(
            (item) =>
                SimulationResultModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    return const [];
  }
}
