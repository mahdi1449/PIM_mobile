import 'package:flutter/material.dart';
import '../../../sports_performance/theme/sp_colors.dart';

class TravelTheme {
  static const Color background = Color(0xFF0A121D);
  static const Color cardBg = Color(0xFF131D29);
  static const Color accentGreen = Color(0xFF1D9E75);
  static const Color accentOrange = Color(0xFFEF9F27);
  static const Color accentBlue = Color(0xFF185FA5);
  static const Color textMuted = Color(0xFF6B7A8D);
  
  static BoxShadow shadow = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 15,
    offset: const Offset(0, 8),
  );
}

class TravelStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const TravelStatBox({
    super.key,
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TravelTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: TravelTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class TravelTimelineNode extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool isLast;

  const TravelTimelineNode({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.white.withOpacity(0.1)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('$time · $subtitle', style: const TextStyle(color: TravelTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
