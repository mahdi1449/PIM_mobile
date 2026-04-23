import 'package:flutter/material.dart';
import '../../../user_management/models/user_management_models.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_course.dart';
import '../../theme/learning_colors.dart';
import '../widgets/course_card.dart';
import 'course_modules_screen.dart';

class LearningCoursesScreen extends StatefulWidget {
  const LearningCoursesScreen({
    super.key,
    required this.session,
    required this.playerId,
  });

  final SessionModel session;
  final String playerId;

  @override
  State<LearningCoursesScreen> createState() => _LearningCoursesScreenState();
}

class _LearningCoursesScreenState extends State<LearningCoursesScreen> {
  final LearningApi _api = LearningApi();
  String _level = '';
  String _type = '';

  Future<List<LearningCourse>> _load() => _api.listCourses(
    playerId: widget.playerId,
    level: _level.isEmpty ? null : _level,
    type: _type.isEmpty ? null : _type,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LearningCourse>>(
      future: _load(),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? const <LearningCourse>[];
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              const Text(
                'Your Courses',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Master the language of the elite sporting world.',
                style: TextStyle(color: LearningColors.textMuted),
              ),
              const SizedBox(height: 18),
              Text(
                'LEVEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: LearningColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip('All Levels', '', _level, (v) => setState(() => _level = v)),
                  _chip('Beginner', 'Beginner', _level, (v) => setState(() => _level = v)),
                  _chip('Intermediate', 'Intermediate', _level, (v) => setState(() => _level = v)),
                  _chip('Advanced', 'Advanced', _level, (v) => setState(() => _level = v)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: LearningColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip('All', '', _type, (v) => setState(() => _type = v)),
                  _chip('Training', 'Training', _type, (v) => setState(() => _type = v)),
                  _chip('Communication', 'Communication', _type, (v) => setState(() => _type = v)),
                  _chip('Medical', 'Medical', _type, (v) => setState(() => _type = v)),
                  _chip('Interview', 'Interview', _type, (v) => setState(() => _type = v)),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (snapshot.hasError)
                Text(
                  'Failed to load courses: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              for (final c in courses) ...[
                LearningCourseCard(
                  course: c,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CourseModulesScreen(
                          playerId: widget.playerId,
                          course: c,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (courses.isEmpty && snapshot.connectionState == ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: Center(
                    child: Text('No courses yet. Run the backend seed to load sample content.'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(
    String label,
    String value,
    String selected,
    ValueChanged<String> onTap,
  ) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? LearningColors.lime.withValues(alpha: 0.18)
              : LearningColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? LearningColors.lime : LearningColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? LearningColors.text : LearningColors.textMuted,
          ),
        ),
      ),
    );
  }
}
