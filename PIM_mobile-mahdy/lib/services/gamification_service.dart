import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GamificationService {
  final ApiService _apiService = ApiService();

  static String get baseUrl => ApiService.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      // Si pas de token, on renvoie les headers sans Auth pour laisser le backend retourner 401
      // ou on pourrait lancer une exception ici.
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Récupérer le profil de gamification d'un utilisateur
  Future<Map<String, dynamic>> getPlayerProfile(String userId) async {
    try {
      final headers = await _headers();
      if (!headers.containsKey('Authorization')) {
        return {'success': false, 'message': 'Session expirée. Veuillez vous reconnecter.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/gamification/profile/$userId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'payload': data};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'message': 'Session invalide (401). Veuillez vous reconnecter.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // Récupérer le classement général
  Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final headers = await _headers();
      if (!headers.containsKey('Authorization')) {
        return {'success': false, 'message': 'Session expirée'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/gamification/leaderboard'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'payload': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur classement'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau'};
    }
  }

  // Ajouter une action
  Future<Map<String, dynamic>> addAction({
    required String userId,
    required String actionType,
    required int points,
    required String moduleId,
    String? description,
  }) async {
    try {
      final body = {
        'userId': userId,
        'actionType': actionType,
        'points': points,
        'moduleId': moduleId,
        'description': description,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/gamification/action'),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'payload': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur action'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau'};
    }
  }
}
