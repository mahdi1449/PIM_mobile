import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../models/media_training_models.dart';

class MediaTrainingService {
  MediaTrainingService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<MediaTrainingDashboard> getDashboard({String? authToken}) async {
    final data = await _get(
      '/sports-performance/media-training/dashboard',
      authToken: authToken,
    );
    return MediaTrainingDashboard.fromJson(data);
  }

  Future<MediaTrainingRoadmap> getRoadmap({String? authToken}) async {
    final data = await _get(
      '/sports-performance/media-training/roadmap',
      authToken: authToken,
    );
    return MediaTrainingRoadmap.fromJson(data);
  }

  Future<MediaTrainingLesson> getLesson(
    String lessonId, {
    String? authToken,
  }) async {
    final data = await _get(
      '/sports-performance/media-training/lessons/$lessonId',
      authToken: authToken,
    );
    return MediaTrainingLesson.fromJson(data);
  }

  Future<MediaTrainingSession> createSession(
    String lessonId, {
    String? authToken,
  }) async {
    final data = await _post(
      '/sports-performance/media-training/sessions',
      body: {'lessonId': lessonId},
      authToken: authToken,
    );
    return MediaTrainingSession.fromJson(data);
  }

  Future<MediaTrainingEvaluationResult> evaluateSession(
    String sessionId,
    List<Map<String, String>> answers, {
    String? transcript,
    String? authToken,
  }) async {
    final normalizedTranscript = transcript?.trim();
    final data = await _post(
      '/sports-performance/media-training/sessions/$sessionId/evaluate',
      body: {
        'answers': answers,
        if (normalizedTranscript != null && normalizedTranscript.isNotEmpty)
          'transcript': normalizedTranscript,
      },
      authToken: authToken,
    );
    return MediaTrainingEvaluationResult.fromJson(data);
  }

  Future<MediaTrainingTranscript> transcribeAudio(
    String filePath, {
    String? authToken,
  }) async {
    final data = await _requestWithAuthFallback(
      authToken: authToken,
      requestBuilder: (token) async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(
            '${ApiService.baseUrl}/sports-performance/media-training/speech/transcribe',
          ),
        );
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
    );
    return MediaTrainingTranscript.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? authToken,
  }) async {
    return _requestWithAuthFallback(
      authToken: authToken,
      requestBuilder: (token) => http.get(
        Uri.parse('${ApiService.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
    String? authToken,
  }) async {
    return _requestWithAuthFallback(
      authToken: authToken,
      requestBuilder: (token) => http.post(
        Uri.parse('${ApiService.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> _requestWithAuthFallback({
    required String? authToken,
    required Future<http.Response> Function(String token) requestBuilder,
  }) async {
    final tokenCandidates = await _resolveTokenCandidates(authToken);
    if (tokenCandidates.isEmpty) {
      throw MediaTrainingException('Authentication required');
    }

    http.Response? lastResponse;
    for (var index = 0; index < tokenCandidates.length; index++) {
      final response = await requestBuilder(tokenCandidates[index]);
      final isLastCandidate = index == tokenCandidates.length - 1;
      if (response.statusCode == 401 && !isLastCandidate) {
        lastResponse = response;
        continue;
      }
      return _handleResponse(response);
    }

    if (lastResponse != null) {
      return _handleResponse(lastResponse);
    }
    throw MediaTrainingException('Request failed');
  }

  Future<List<String>> _resolveTokenCandidates(String? authToken) async {
    final candidates = <String>[];
    final explicitToken = _normalizeToken(authToken);
    final storedToken = _normalizeToken(await _apiService.getToken());

    if (explicitToken != null && explicitToken.isNotEmpty) {
      candidates.add(explicitToken);
    }
    if (storedToken != null &&
        storedToken.isNotEmpty &&
        !candidates.contains(storedToken)) {
      candidates.add(storedToken);
    }

    return candidates;
  }

  String? _normalizeToken(String? token) {
    final initial = token?.trim();
    if (initial == null || initial.isEmpty) {
      return null;
    }

    var trimmed = initial;

    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }

    // Handle malformed values like "Bearer Bearer <jwt>".
    while (trimmed.toLowerCase().startsWith('bearer ')) {
      trimmed = trimmed.substring(7).trim();
    }

    trimmed = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final dynamic decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw MediaTrainingException('Unexpected server response');
    }

    final message = decoded is Map<String, dynamic>
        ? _extractMessage(decoded)
        : 'Request failed';
    throw MediaTrainingException(message);
  }

  String _extractMessage(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message is List) {
      return message.map((item) => item.toString()).join(', ');
    }
    return (message ?? 'Request failed').toString();
  }
}

class MediaTrainingException implements Exception {
  MediaTrainingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MediaTrainingTranscript {
  const MediaTrainingTranscript({
    required this.text,
    this.languageCode,
    this.languageProbability,
  });

  final String text;
  final String? languageCode;
  final double? languageProbability;

  factory MediaTrainingTranscript.fromJson(Map<String, dynamic> json) {
    final probability = json['languageProbability'];
    return MediaTrainingTranscript(
      text: (json['text'] ?? '').toString(),
      languageCode: json['languageCode']?.toString(),
      languageProbability: probability is num ? probability.toDouble() : null,
    );
  }
}
