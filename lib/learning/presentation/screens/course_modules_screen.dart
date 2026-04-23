import 'package:flutter/material.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_course.dart';
import '../../data/models/learning_lesson_summary.dart';
import '../../data/models/learning_module.dart';
import '../../theme/learning_colors.dart';
import '../widgets/learning_top_bar.dart';
import 'course_details_screen.dart';
import 'lesson_detail_screen.dart';

class CourseModulesScreen extends StatefulWidget {
  const CourseModulesScreen({
    super.key,
    required this.playerId,
    required this.course,
  });

  final String playerId;
  final LearningCourse course;

  @override
  State<CourseModulesScreen> createState() => _CourseModulesScreenState();
}

class _CourseModulesScreenState extends State<CourseModulesScreen> {
  final LearningApi _api = LearningApi();
  String? _expandedModuleId;

  Future<_Vm> _load() async {
    final modules = await _api.courseModules(widget.course.id, playerId: widget.playerId);
    final Map<String, List<LearningLessonSummary>> lessonsByModule = {};
    for (final m in modules) {
      final res = await _api.moduleLessons(m.id, playerId: widget.playerId);
      lessonsByModule[m.id] = (res['lessons'] as List<LearningLessonSummary>? ?? const []);
    }
    return _Vm(modules: modules, lessonsByModule: lessonsByModule);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Vm>(
      future: _load(),
      builder: (context, snapshot) {
        final vm = snapshot.data;
        final modules = vm?.modules ?? const <LearningModule>[];
        if (_expandedModuleId == null && modules.isNotEmpty) {
          _expandedModuleId = modules.first.id;
        }

        return Scaffold(
          backgroundColor: LearningColors.surface,
          appBar: LearningTopBar(
            title: 'ODIN',
            avatarLetter: widget.playerId.isNotEmpty ? widget.playerId[0] : 'O',
          ),
          body: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                _hero(widget.course),
                const SizedBox(height: 14),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator())),
                if (snapshot.hasError)
                  Text('Failed to load modules: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                if (modules.isEmpty && snapshot.connectionState == ConnectionState.done)
                  _EmptyCourseContentCard(
                    onViewLessons: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailsScreen(
                            playerId: widget.playerId,
                            course: widget.course,
                          ),
                        ),
                      );
                    },
                    onRefresh: () => setState(() {}),
                  ),
                for (final m in modules) ...[
                  _moduleCard(m, vm?.lessonsByModule[m.id] ?? const []),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hero(LearningCourse course) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: LearningColors.navy,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LearningColors.lime,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                course.level.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleCard(LearningModule module, List<LearningLessonSummary> lessons) {
    final expanded = _expandedModuleId == module.id;
    final progress = module.lessonCount == 0 ? 0.0 : module.completedLessons / module.lessonCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: expanded ? LearningColors.lime : LearningColors.border, width: expanded ? 1.2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _expandedModuleId = expanded ? null : module.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(module.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.expand_more_rounded, color: LearningColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE9EDF3),
                  valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${module.completedLessons}/${module.lessonCount} lessons completed',
                style: TextStyle(color: LearningColors.textMuted, fontWeight: FontWeight.w700),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      for (final l in lessons) ...[
                        _lessonTile(l),
                        const SizedBox(height: 10),
                      ]
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _lessonTile(LearningLessonSummary lesson) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(playerId: widget.playerId, lessonId: lesson.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lesson.completed ? LearningColors.lime.withValues(alpha: 0.10) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lesson.completed ? LearningColors.lime : LearningColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lesson.completed ? LearningColors.lime : LearningColors.card,
              ),
              child: Icon(
                lesson.completed ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: LearningColors.text,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LESSON ${lesson.order}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: LearningColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    '${lesson.exerciseCount} exercises',
                    style: TextStyle(color: LearningColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: LearningColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Vm {
  const _Vm({required this.modules, required this.lessonsByModule});
  final List<LearningModule> modules;
  final Map<String, List<LearningLessonSummary>> lessonsByModule;
}

class _EmptyCourseContentCard extends StatelessWidget {
  const _EmptyCourseContentCard({
    required this.onViewLessons,
    required this.onRefresh,
  });

  final VoidCallback onViewLessons;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LearningColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No modules found for this course yet.',
            style: TextStyle(
              color: LearningColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "If you're using the sample learning content, run the backend seed and pull to refresh.",
            style: TextStyle(color: LearningColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: LearningColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onRefresh,
                  child: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LearningColors.lime,
                    foregroundColor: LearningColors.text,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: onViewLessons,
                  child: const Text('View lessons', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
