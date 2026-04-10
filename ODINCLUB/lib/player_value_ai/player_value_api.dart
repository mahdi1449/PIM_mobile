import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'player_value_models.dart';

class PlayerValueApi {
  PlayerValueApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PlayerValueResponse> predict(PlayerValueRequest request) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.playerValueAiBaseUrl}/predict-player-value'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Player value AI error: ${response.body}');
    }

    return PlayerValueResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
