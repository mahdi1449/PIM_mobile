import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../models/travel_model.dart';

class TravelApiService {
  final String baseUrl = AppConfig.apiBaseUrl;

  /// Construit les en-têtes HTTP avec le token JWT récupéré depuis SharedPreferences.
  /// Lève une exception si l'utilisateur n'est pas authentifié.
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Récupère la liste de tous les voyages du club depuis le backend.
  Future<List<TravelModel>> fetchTravels(String clubId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/travel?clubId=$clubId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => TravelModel.fromJson(j)).toList();
    }
    throw Exception('Erreur lors du chargement des voyages: ${response.statusCode}');
  }

  /// Récupère les matchs à venir du club pour permettre la liaison voyage-match.
  Future<List<Map<String, dynamic>>> fetchUpcomingMatches(String clubId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/matches?clubId=$clubId&upcoming=true'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  /// Récupère uniquement les voyages dans lesquels un joueur spécifique est inscrit.
  Future<List<TravelModel>> fetchPlayerTravels(String clubId, String playerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/travel/player/$playerId?clubId=$clubId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => TravelModel.fromJson(j)).toList();
    }
    throw Exception('Erreur voyages joueur: ${response.statusCode}');
  }

  /// Récupère les détails complets d'un voyage, incluant les occupants des chambres.
  Future<TravelModel> fetchTravelDetail(String id, String clubId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/travel/$id?clubId=$clubId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return TravelModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Voyage non trouvé');
  }

  /// Crée un nouveau voyage. Le backend enrichit automatiquement les données GPS.
  Future<TravelModel> createTravel(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/travel'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return TravelModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur création voyage: ${response.body}');
  }

  /// Met à jour les informations d'un voyage existant.
  Future<TravelModel> updateTravel(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/travel/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return TravelModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erreur mise à jour voyage: ${response.body}');
  }

  /// Change le statut d'un voyage (ex: 'draft' → 'confirmed' → 'completed').
  /// Le passage à 'completed' déclenche les récompenses XP pour les participants.
  Future<void> updateTravelStatus(String id, String clubId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/travel/$id/status?clubId=$clubId'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur changement statut: ${response.body}');
    }
  }

  /// Récupère les statistiques de voyage du club (statuts, modes de transport).
  Future<List<dynamic>> fetchTravelStats(String clubId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/travel/stats?clubId=$clubId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  /// Recherche des aéroports proches d'une ville via l'IA géographique du backend.
  Future<List<AirportInfo>> searchAirports(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/travel/airports?city=${Uri.encodeComponent(city)}'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((j) => AirportInfo.fromJson(j)).toList();
    }
    return [];
  }

  /// Convertit une adresse textuelle en coordonnées GPS (lat/lng).
  Future<Map<String, double>?> geocodeAddress(String address) async {
    final response = await http.get(
      Uri.parse('$baseUrl/travel/geocode?address=${Uri.encodeComponent(address)}'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null) {
        return {'lat': data['lat'].toDouble(), 'lng': data['lng'].toDouble()};
      }
    }
    return null;
  }

  /// Assigne des occupants à une chambre d'hôtel spécifique d'un voyage.
  Future<void> updateRoomAssignment({
    required String travelId,
    required String clubId,
    required String roomNumber,
    String? occupant1,
    String? occupant2,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/travel/$travelId/rooms/$roomNumber?clubId=$clubId'),
      headers: await _authHeaders(),
      body: jsonEncode({'occupant1': occupant1, 'occupant2': occupant2}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur modification chambre: ${response.body}');
    }
  }

  /// Supprime définitivement un voyage et toutes ses données associées.
  Future<void> deleteTravel(String id, String clubId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/travel/$id?clubId=$clubId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression: ${response.body}');
    }
  }

  String? lastError; // Pour le diagnostic UI

  /// Recherche de lieux en mode hybride : tente d'abord Photon directement (plus rapide),
  /// puis bascule sur le proxy backend si l'appel direct échoue (ex: en émulateur).
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    lastError = null;
    try {
      // TENTATIVE 1 : Photon Direct (Plus rapide)
      final response = await http.get(
        Uri.parse('https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=10&lang=fr'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parsePhotonResults(response.body);
      }
      
      // TENTATIVE 2 : Proxy Backend (Si direct bloqué par l'émulateur)
      print('TravelApiService: Photon direct failed (${response.statusCode}), trying Proxy...');
      final proxyResponse = await http.get(
        Uri.parse('$baseUrl/travel/search?q=${Uri.encodeComponent(query)}'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (proxyResponse.statusCode == 200) {
        final List data = jsonDecode(proxyResponse.body);
        return data.map((item) => {
          'display_name': item['address'],
          'name': item['name'],
          'lat': item['lat'].toString(),
          'lon': item['lng'].toString(),
          'type': item['type'],
        }).toList();
      }
      
      lastError = 'Serveur non disponible (Code: ${proxyResponse.statusCode})';
    } catch (e) {
      lastError = 'Erreur réseau: ${e.toString()}';
      print('TravelApiService Error: $e');
    }
    return [];
  }

  /// Transforme la réponse GeoJSON de l'API Photon en une liste de lieux normalisés.
  List<Map<String, dynamic>> _parsePhotonResults(String body) {
    final data = jsonDecode(body);
    final List features = data['features'] ?? [];
    return features.map((f) {
      final props = f['properties'] ?? {};
      final coords = f['geometry']['coordinates'] ?? [0.0, 0.0];
      String displayName = props['name'] ?? '';
      if (props['city'] != null) displayName += ', ${props['city']}';
      if (props['country'] != null) displayName += ', ${props['country']}';
      return {
        'display_name': displayName,
        'name': props['name'] ?? 'Lieu inconnu',
        'lat': coords[1].toString(),
        'lon': coords[0].toString(),
        'type': props['osm_value'] ?? 'place',
      };
    }).toList();
  }

  /// Recherche des hôtels par nom, en affinant la recherche avec la ville si fournie.
  Future<List<Map<String, dynamic>>> searchHotels(String hotelName, {String? city}) async {
    final query = city != null ? '$hotelName, $city' : hotelName;
    return searchPlaces(query);
  }

  /// Version directe de la recherche d'aéroports, passant par le backend Photon.
  /// Inclut un timeout de 10 secondes pour ne pas bloquer l'UI.
  Future<List<AirportInfo>> searchAirportsDirect(String city) async {
    try {
      // On passe par le backend qui est maintenant migré vers Photon pour plus de fiabilité
      final response = await http.get(
        Uri.parse('$baseUrl/travel/airports?city=${Uri.encodeComponent(city)}'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => AirportInfo.fromJson(j)).toList();
      }
    } catch (e) {
      print('TravelApiService: Airport Search Error ($city) -> $e');
    }
    return [];
  }
}
