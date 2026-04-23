import 'package:flutter/material.dart';
import '../../theme/learning_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 160,
    this.strokeWidth = 14,
    this.label,
  });

  final double value; // 0..1
  final double size;
  final double strokeWidth;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE9EDF3),
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: v),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, anim, _) {
                return CircularProgressIndicator(
                  value: anim,
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(LearningColors.lime),
                  backgroundColor: Colors.transparent,
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(v * 100).round()}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: LearningColors.text,
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: LearningColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
