import 'learning_api.dart';
import 'models/learning_course.dart';
import 'models/learning_lesson_detail.dart';
import 'models/learning_lesson_summary.dart';
import 'models/learning_module.dart';

class LearningRepository {
  LearningRepository({LearningApi? api}) : _api = api ?? LearningApi();

  final LearningApi _api;

  Future<List<LearningCourse>> listCourses({
    required String playerId,
    String? level,
    String? type,
  }) =>
      _api.listCourses(playerId: playerId, level: level, type: type);

  Future<List<LearningModule>> listModules({
    required String courseId,
    required String playerId,
  }) =>
      _api.courseModules(courseId, playerId: playerId);

  Future<List<LearningLessonSummary>> listLessonsForModule({
    required String moduleId,
    required String playerId,
  }) async {
    final res = await _api.moduleLessons(moduleId, playerId: playerId);
    return (res['lessons'] as List<LearningLessonSummary>? ?? const []);
  }

  Future<LearningLessonDetail> getLessonDetail({
    required String lessonId,
    required String playerId,
  }) =>
      _api.lessonDetail(lessonId, playerId: playerId);

  Future<Map<String, dynamic>> submitExercise({
    required String playerId,
    required String exerciseId,
    required Map<String, dynamic> answers,
  }) =>
      _api.submitExercise(playerId: playerId, exerciseId: exerciseId, answers: answers);
}

