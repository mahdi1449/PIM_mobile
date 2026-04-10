import 'package:flutter/material.dart';

/// Color palette for the AI scouting module.
/// NOW ALIGNED with SPColors for visual consistency.
class AiColors {
  AiColors._();

  // Primary — matches SPColors.primaryBlue
  static const Color primary = Color(0xFF23AED1);
  static const Color primaryLight = Color(0xFF90CCDD);
  static const Color primaryDark = Color(0xFF05708D);

  // Backgrounds — matches SPColors backgrounds
  static const Color backgroundDark = Color(0xFFF7FBFD);

  // Cards & Surfaces
  static const Color cardDark = Color(0xFFFFFFFF);

  // Borders — matches SPColors.borderPrimary
  static const Color borderDark = Color(0xFFD6E6EE);

  // Text — matches SPColors text system
  static const Color textSecondary = Color(0xFF486A78);
  static const Color textTertiary = Color(0xFF7FA1AF);
  static const Color textMuted = Color(0xFF7FA1AF);

  // Status — matches SPColors status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF23AED1);

  static Color matchColor(double percentage) {
    if (percentage >= 90) return primary;
    if (percentage >= 80) return success;
    if (percentage >= 70) return warning;
    return textSecondary;
  }

  // Glass effect — matches SP card style (backgroundSecondary with border)
  static const Color glassBackground = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFD6E6EE);
}
