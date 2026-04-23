import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/learning_repository.dart';
import '../../data/models/learning_course.dart';
import '../../data/models/learning_lesson_detail.dart';
import '../../data/models/learning_lesson_summary.dart';
import '../../data/models/learning_module.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository();
});

final learningCoursesProvider = FutureProvider.family<List<LearningCourse>, ({String playerId, String? level, String? type})>(
  (ref, args) async {
    final repo = ref.watch(learningRepositoryProvider);
    return repo.listCourses(playerId: args.playerId, level: args.level, type: args.type);
  },
);

final learningModulesProvider = FutureProvider.family<List<LearningModule>, ({String courseId, String playerId})>(
  (ref, args) async {
    final repo = ref.watch(learningRepositoryProvider);
    return repo.listModules(courseId: args.courseId, playerId: args.playerId);
  },
);

final learningModuleLessonsProvider = FutureProvider.family<List<LearningLessonSummary>, ({String moduleId, String playerId})>(
  (ref, args) async {
    final repo = ref.watch(learningRepositoryProvider);
    return repo.listLessonsForModule(moduleId: args.moduleId, playerId: args.playerId);
  },
);

final learningLessonDetailProvider = FutureProvider.family<LearningLessonDetail, ({String lessonId, String playerId})>(
  (ref, args) async {
    final repo = ref.watch(learningRepositoryProvider);
    return repo.getLessonDetail(lessonId: args.lessonId, playerId: args.playerId);
  },
);

