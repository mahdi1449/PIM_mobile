import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../models/tactical_animation.dart';
import '../models/tactics.dart';

class TacticsService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<TacticalPlan> suggestFormation({
    String? opponentStyle,
    String? opponentTeamName,
    String? preferredFormation,
    List<String>? strengths,
    List<String>? weaknesses,
    List<OpponentSquadPlayerInput>? opponentSquad,
  }) async {
    try {
      final request = OpponentAnalysisRequest(
        opponentStyle: opponentStyle,
        opponentTeamName: opponentTeamName,
        preferredFormation: preferredFormation,
        strengths: strengths,
        weaknesses: weaknesses,
        opponentSquad: opponentSquad,
      );

      final response = await http
          .post(
            Uri.parse('$_baseUrl/tactics/analyze'),
            headers: await _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return TacticalPlan.fromJson(decoded);
        }
        if (decoded is Map) {
          return TacticalPlan.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        throw const HttpException('Unexpected tactics payload format');
      }
      throw HttpException('Failed to generate tactics: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error calling AI tactics: $e');
    }
  }

  static Future<TacticalAnimationOptions> getAnimationOptions() async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/tactics/animation/options'),
            headers: await _headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return TacticalAnimationOptions.fromJson(decoded);
        }
        if (decoded is Map) {
          return TacticalAnimationOptions.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        throw const HttpException(
            'Unexpected animation options payload format');
      }
      throw HttpException(
          'Failed to load animation options: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading tactical animation options: $e');
    }
  }

  static Future<TacticalAnimation> generateAnimation(
    TacticalAnimationRequest request,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/tactics/animation'),
            headers: await _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return TacticalAnimation.fromJson(decoded);
        }
        if (decoded is Map) {
          return TacticalAnimation.fromJson(
            decoded.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
        throw const HttpException('Unexpected animation payload format');
      }
      throw HttpException(
          'Failed to generate animation: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error calling tactical animation AI: $e');
    }
  }
}
