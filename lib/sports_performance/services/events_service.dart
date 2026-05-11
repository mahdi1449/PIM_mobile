import '../models/event.dart';
import '../models/event_player.dart';
import 'api_client.dart';

class EventsService {
  final ApiClient _apiClient;

  EventsService(this._apiClient);

  /// Récupère la liste des événements sportifs avec des filtres optionnels.
  /// Gère dynamiquement différents formats de réponse JSON (List ou Map avec clé 'data').
  Future<List<Event>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status.value;
      }

      final response = await _apiClient.get(
        '/sports-events',
        queryParameters: queryParams,
      );
      
      dynamic rawData = response.data;
      List<dynamic> listData = [];
      
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map) {
        if (rawData['data'] != null) {
          if (rawData['data'] is List) {
            listData = rawData['data'];
          } else if (rawData['data'] is Map && rawData['data']['events'] is List) {
            listData = rawData['data']['events'];
          }
        } else if (rawData['events'] is List) {
          listData = rawData['events'];
        }
      }
      
      return listData.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  /// Récupère les détails d'un événement unique par son identifiant.
  Future<Event> getEvent(String id) async {
    try {
      final response = await _apiClient.get('/sports-events/$id');
      return Event.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'événement: $e');
    }
  }

  /// Crée un nouvel événement (match ou entraînement) sur le backend.
  Future<Event> createEvent(Event event) async {
    try {
      final response = await _apiClient.post(
        '/sports-events',
        data: event.toJson(),
      );
      return Event.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'événement: $e');
    }
  }

  /// Met à jour les informations d'un événement existant.
  Future<Event> updateEvent(String id, Event event) async {
    try {
      final response = await _apiClient.patch(
        '/sports-events/$id',
        data: event.toJson(),
      );
      return Event.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }

  /// Supprime un événement de la base de données.
  Future<void> deleteEvent(String id) async {
    try {
      await _apiClient.delete('/sports-events/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'événement: $e');
    }
  }

  /// Clôture un événement, empêchant toute modification ultérieure des participants.
  Future<Event> closeEvent(String id) async {
    try {
      final response = await _apiClient.post('/sports-events/$id/close');
      return Event.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la clôture de l\'événement: $e');
    }
  }

  /// Lance l'analyse IA sur tous les joueurs complétés d'un événement.
  /// L'IA va traiter les résultats des tests pour générer des recommandations de recrutement.
  /// Retourne un récapitulatif : {analyzed, failed, results}.
  Future<Map<String, dynamic>> analyzeEvent(String eventId) async {
    try {
      final response = await _apiClient.post('/sports-events/$eventId/analyze');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Erreur lors de l\'analyse IA: $e');
    }
  }

  /// Enregistre la décision finale de recrutement prise par le coach pour un joueur.
  Future<void> setRecruitmentDecision(
    String eventId,
    String playerId, {
    required bool decision,
  }) async {
    try {
      await _apiClient.patch(
        '/sports-events/$eventId/players/$playerId/decision',
        data: {'decision': decision},
      );
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la décision: $e');
    }
  }

  /// Récupère la liste des joueurs (participants) associés à un événement.
  /// Gère différents formats de parsing pour assurer la compatibilité avec le backend.
  Future<List<EventPlayer>> getEventPlayers(String eventId) async {
    try {
      final response = await _apiClient.get('/sports-events/$eventId/players');
      
      dynamic rawData = response.data;
      List<dynamic> listData = [];
      
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map) {
        if (rawData['data'] != null) {
          if (rawData['data'] is List) {
            listData = rawData['data'];
          } else if (rawData['data'] is Map && rawData['data']['players'] is List) {
            listData = rawData['data']['players'];
          }
        } else if (rawData['players'] is List) {
          listData = rawData['players'];
        }
      }
      
      return listData.map((json) => EventPlayer.fromJson(json)).toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des joueurs de l\'événement: $e');
    }
  }

  /// Ajoute un joueur à la liste des participants d'un événement.
  Future<EventPlayer> addPlayerToEvent(
    String eventId,
    String playerId, {
    String status = 'confirmed',
  }) async {
    try {
      final response = await _apiClient.post(
        '/sports-events/$eventId/players',
        data: {
          'playerId': playerId,
          'status': status,
        },
      );
      return EventPlayer.fromJson(response.data);
    } catch (e) {
      throw Exception(
          'Erreur lors de l\'ajout du joueur à l\'événement: $e');
    }
  }

  /// Retire un joueur d'un événement spécifique.
  Future<void> removePlayerFromEvent(String eventId, String playerId) async {
    try {
      await _apiClient.delete('/sports-events/$eventId/players/$playerId');
    } catch (e) {
      throw Exception(
          'Erreur lors de la suppression du joueur de l\'événement: $e');
    }
  }

  /// Met à jour le statut (présent, blessé, exclu) ou les notes du coach pour un participant.
  Future<EventPlayer> updateEventPlayer(
    String eventId,
    String playerId, {
    String? status,
    String? coachNotes,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/sports-events/$eventId/players/$playerId',
        data: {
          if (status != null) 'status': status,
          if (coachNotes != null) 'coachNotes': coachNotes,
        },
      );
      return EventPlayer.fromJson(response.data);
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour du statut du joueur: $e');
    }
  }
}

