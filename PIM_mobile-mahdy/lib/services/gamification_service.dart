import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GamificationService {
  final ApiService _apiService = ApiService();

  static String get baseUrl => ApiService.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Récupérer le profil de gamification d'un utilisateur
  Future<Map<String, dynamic>> getPlayerProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/profile/$userId'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la récupération du profil'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // Récupérer le classement général
  Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/gamification/leaderboard'),
        headers: await _headers(),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la récupération du classement'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }

  // Ajouter une action (ex: note coach, présence entrainement)
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
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout de l\'action'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau: ${e.toString()}'};
    }
  }
}
