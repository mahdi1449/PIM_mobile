import 'package:dio/dio.dart';
import '../../sports_performance/services/api_client.dart';
import 'models/learning_course.dart';
import 'models/learning_lesson.dart';
import 'models/learning_lesson_detail.dart';
import 'models/learning_lesson_summary.dart';
import 'models/learning_module.dart';
import 'models/learning_progress.dart';
import 'models/learning_quiz.dart';
import 'models/learning_task.dart';

class LearningApi {
  LearningApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<LearningCourse>> listCourses({
    String? playerId,
    String? level,
    String? type,
  }) async {
    final query = <String, dynamic>{
      if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      if (level != null && level.isNotEmpty) 'level': level,
      if (type != null && type.isNotEmpty) 'type': type,
    };
    final Response res = await _client.get('/courses', queryParameters: query);
    final List data = res.data as List;
    return data
        .map((e) => LearningCourse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> courseLessons(
    String courseId, {
    String? playerId,
  }) async {
    final Response res = await _client.get(
      '/courses/$courseId/lessons',
      queryParameters: {
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      },
    );
    final map = Map<String, dynamic>.from(res.data as Map);
    final lessons = (map['lessons'] as List? ?? const [])
        .map((e) => LearningLesson.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return {
      'course': Map<String, dynamic>.from(map['course'] as Map),
      'lessons': lessons,
    };
  }

  Future<List<LearningModule>> courseModules(
    String courseId, {
    String? playerId,
  }) async {
    final Response res = await _client.get(
      '/courses/$courseId/modules',
      queryParameters: {
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      },
    );
    final List data = res.data as List;
    return data
        .map((e) => LearningModule.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> moduleLessons(
    String moduleId, {
    String? playerId,
  }) async {
    final Response res = await _client.get(
      '/modules/$moduleId/lessons',
      queryParameters: {
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      },
    );
    final map = Map<String, dynamic>.from(res.data as Map);
    final lessons = (map['lessons'] as List? ?? const [])
        .map((e) => LearningLessonSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return {
      'module': Map<String, dynamic>.from(map['module'] as Map? ?? const {}),
      'lessons': lessons,
    };
  }

  Future<LearningLessonDetail> lessonDetail(
    String lessonId, {
    String? playerId,
  }) async {
    final Response res = await _client.get(
      '/lessons/$lessonId',
      queryParameters: {
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
      },
    );
    return LearningLessonDetail.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<LearningProgress>> playerProgress(String playerId) async {
    final Response res = await _client.get('/progress/player/$playerId');
    final List data = res.data as List;
    return data
        .map((e) => LearningProgress.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<LearningProgress> updateProgress({
    required String playerId,
    required String courseId,
    String? lessonId,
    int? progressPercentage,
  }) async {
    final Response res = await _client.post(
      '/progress/update',
      data: {
        'playerId': playerId,
        'courseId': courseId,
        if (lessonId != null) 'lessonId': lessonId,
        if (progressPercentage != null)
          'progressPercentage': progressPercentage,
      },
    );
    return LearningProgress.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<List<LearningQuizQuestion>> lessonQuizzes(String lessonId) async {
    final Response res = await _client.get('/lessons/$lessonId/quizzes');
    final List data = res.data as List;
    return data
        .map((e) => LearningQuizQuestion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<LearningTask>> lessonTasks(String lessonId) async {
    final Response res = await _client.get('/lessons/$lessonId/tasks');
    final List data = res.data as List;
    return data
        .map((e) => LearningTask.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> submitExercise({
    required String playerId,
    required String exerciseId,
    required Map<String, dynamic> answers,
  }) async {
    final Response res = await _client.post(
      '/exercises/submit',
      data: {
        'playerId': playerId,
        'exerciseId': exerciseId,
        'answers': answers,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<LearningQuizSubmitResult> submitQuiz({
    required String playerId,
    required String lessonId,
    required Map<String, String> answersByQuizId,
  }) async {
    final Response res = await _client.post(
      '/quiz/submit',
      data: {
        'playerId': playerId,
        'lessonId': lessonId,
        'answers': answersByQuizId.entries
            .map((e) => {'quizId': e.key, 'answer': e.value})
            .toList(),
      },
    );
    return LearningQuizSubmitResult.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<Map<String, dynamic>> chat({
    required String mode,
    required List<Map<String, String>> messages,
    String? playerId,
  }) async {
    final Response res = await _client.post(
      '/learning/chat',
      data: {
        if (playerId != null && playerId.isNotEmpty) 'playerId': playerId,
        'mode': mode,
        'messages': messages,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
