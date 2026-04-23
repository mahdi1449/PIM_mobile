import 'package:flutter/material.dart';
import '../../data/models/learning_course.dart';
import '../../theme/learning_colors.dart';

class LearningCourseCard extends StatelessWidget {
  const LearningCourseCard({super.key, required this.course, this.onTap});

  final LearningCourse course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (course.progressPercentage.clamp(0, 100)) / 100.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LearningColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LearningColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: LearningColors.lime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: LearningColors.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: LearningColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _pill(course.level),
                          const SizedBox(width: 8),
                          _pill(course.type, outlined: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: LearningColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE9EDF3),
                      valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${course.progressPercentage}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: LearningColors.text,
                  ),
                ),
              ],
            ),
            if (course.recommended) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: LearningColors.lime.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: LearningColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.recommendedReasons.isEmpty
                          ? 'Picked for you'
                          : course.recommendedReasons.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: LearningColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: LearningColors.border) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: LearningColors.textMuted,
        ),
      ),
    );
  }
}
