import 'package:flutter/material.dart';
import '../../../user_management/models/user_management_models.dart';
import '../../data/learning_api.dart';
import '../../data/models/learning_course.dart';
import '../../theme/learning_colors.dart';
import '../widgets/progress_ring.dart';
import 'course_modules_screen.dart';
import 'learning_chat_screen.dart';

class LearningDashboardScreen extends StatefulWidget {
  const LearningDashboardScreen({
    super.key,
    required this.session,
    required this.playerId,
  });

  final SessionModel session;
  final String playerId;

  @override
  State<LearningDashboardScreen> createState() =>
      _LearningDashboardScreenState();
}

class _LearningDashboardScreenState extends State<LearningDashboardScreen> {
  final LearningApi _api = LearningApi();

  Future<List<LearningCourse>> _load() =>
      _api.listCourses(playerId: widget.playerId);

  @override
  Widget build(BuildContext context) {
    final name = (widget.session.firstName ?? '').trim().isEmpty
        ? 'Athlete'
        : (widget.session.firstName ?? '').trim();

    return FutureBuilder<List<LearningCourse>>(
      future: _load(),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? const <LearningCourse>[];
        final inProgress = courses
            .where((c) => !c.completed && c.progressPercentage > 0)
            .toList();
        final completed = courses.where((c) => c.completed).length;
        final overall = courses.isEmpty
            ? 0
            : (courses.fold<int>(0, (sum, c) => sum + c.progressPercentage) /
                  courses.length);
        final continueCourse = (inProgress.isNotEmpty
            ? inProgress.first
            : (courses.isNotEmpty ? courses.first : null));
        final recommended = courses
            .where((c) => c.recommended)
            .take(6)
            .toList();

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            children: [
              Text(
                'Welcome back,\n$name!',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: LearningColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You're crushing your weekly training goals.",
                style: TextStyle(color: LearningColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: LearningColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: LearningColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ProgressRing(
                        value: overall / 100,
                        label: 'OVERALL',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Performance\nOverview',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        color: LearningColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statCard('$completed', 'Courses\nCompleted'),
                        const SizedBox(width: 10),
                        _statCard('12', 'Day\nStreak'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (continueCourse != null) _continueCard(continueCourse),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended for\nYou',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: LearningColors.limeDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = recommended[i];
                    return _recommendedCard(c);
                  },
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Practice with AI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LearningChatScreen(playerId: widget.playerId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LearningColors.navy,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic_none_rounded, color: LearningColors.lime),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Chatbot: interview & press conference practice',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting) ...[
                const SizedBox(height: 18),
                const Center(child: CircularProgressIndicator()),
              ],
              if (snapshot.hasError) ...[
                const SizedBox(height: 18),
                Text(
                  'Failed to load learning data: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: LearningColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: LearningColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueCard(LearningCourse course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LearningColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE LEARNING',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              color: LearningColors.lime,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: course.progressPercentage.clamp(0, 100) / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LearningColors.lime,
                foregroundColor: LearningColors.text,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourseModulesScreen(
                      playerId: widget.playerId,
                      course: course,
                    ),
                  ),
                );
              },
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendedCard(LearningCourse course) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CourseModulesScreen(playerId: widget.playerId, course: course),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LearningColors.border),
          color: LearningColors.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: LearningColors.navy2,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: LearningColors.lime,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    course.level.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: LearningColors.text,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: LearningColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
