import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../models/learning_models.dart';

class LearningApiService {
  LearningApiService({required this.token});

  final String token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  String get _baseUrl => AppConfig.apiBaseUrl;

  String resolveAssetUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConfig.baseUrl}$path';
  }

  Future<List<LearningCourse>> getCourses({String? playerId}) async {
    final uri = Uri.parse('$_baseUrl/courses').replace(
      queryParameters: playerId == null || playerId.isEmpty
          ? null
          : {'playerId': playerId},
    );
    final data = await _getList(uri);
    return data.map(LearningCourse.fromJson).toList();
  }

  Future<List<LearningCourse>> getRecommendations(String playerId) async {
    final data = await _getMap(
      Uri.parse('$_baseUrl/courses/recommended/player/$playerId'),
    );
    final list = data['recommendations'] is List
        ? data['recommendations'] as List
        : const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(LearningCourse.fromJson)
        .toList();
  }

  Future<LearningDashboard> getDashboard(String playerId) async {
    final data = await _getMap(
      Uri.parse('$_baseUrl/learning/dashboard/player/$playerId'),
    );
    return LearningDashboard.fromJson(data);
  }

  Future<CourseLessonsResponse> getLessons(String courseId) async {
    final data = await _getMap(
      Uri.parse('$_baseUrl/courses/$courseId/lessons'),
    );
    final course = LearningCourse.fromJson(
      data['course'] as Map<String, dynamic>,
    );
    final lessons =
        (data['lessons'] is List ? data['lessons'] as List : const [])
            .whereType<Map<String, dynamic>>()
            .map(LearningLesson.fromJson)
            .toList();
    return CourseLessonsResponse(course: course, lessons: lessons);
  }

  Future<LearningProgress> updateProgress({
    required String playerId,
    required String courseId,
    String? lessonId,
    int? progressPercentage,
    bool? completed,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/progress/update'),
      headers: _headers,
      body: jsonEncode({
        'playerId': playerId,
        'courseId': courseId,
        if (lessonId != null) 'lessonId': lessonId,
        if (progressPercentage != null)
          'progressPercentage': progressPercentage,
        if (completed != null) 'completed': completed,
      }),
    );
    final data = _decode(response);
    return LearningProgress.fromJson(data);
  }

  Future<List<LearningQuizQuestion>> getQuiz(String lessonId) async {
    final data = await _getList(Uri.parse('$_baseUrl/quiz/lesson/$lessonId'));
    return data.map(LearningQuizQuestion.fromJson).toList();
  }

  Future<List<LearningExercise>> getLessonExercises(String lessonId) async {
    final data = await _getList(
      Uri.parse('$_baseUrl/learning/lessons/$lessonId/exercises'),
    );
    return data.map(LearningExercise.fromJson).toList();
  }

  Future<QuizResult> submitQuiz({
    required String playerId,
    required String lessonId,
    required Map<String, String> answers,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/quiz/submit'),
      headers: _headers,
      body: jsonEncode({
        'playerId': playerId,
        'lessonId': lessonId,
        'answers': answers.entries
            .map((entry) => {'quizId': entry.key, 'answer': entry.value})
            .toList(),
      }),
    );
    final data = _decode(response);
    return QuizResult.fromJson(data);
  }

  Future<String> sendChatMessage({
    required String playerId,
    required String message,
    required String mode,
    List<Map<String, String>> history = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/learning/chatbot'),
      headers: _headers,
      body: jsonEncode({
        'playerId': playerId,
        'message': message,
        'mode': mode,
        'history': history,
      }),
    );
    final data = _decode(response);
    return (data['reply'] ?? '').toString();
  }

  Future<Map<String, dynamic>> _getMap(Uri uri) async {
    final response = await http.get(uri, headers: _headers);
    return _decode(response);
  }

  Future<List<Map<String, dynamic>>> _getList(Uri uri) async {
    final response = await http.get(uri, headers: _headers);
    final data = _decode(response);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  dynamic _decode(http.Response response) {
    final dynamic data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    final message = data is Map<String, dynamic>
        ? (data['message'] ?? 'Learning request failed').toString()
        : 'Learning request failed';
    throw Exception(message);
  }
}

class CourseLessonsResponse {
  CourseLessonsResponse({required this.course, required this.lessons});

  final LearningCourse course;
  final List<LearningLesson> lessons;
}
