import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF23AED1); // Primary
  static const Color secondary = Color(0xFF05708D); // Secondary
  static const Color accent = Color(0xFF90CCDD); // Accent
  static const Color primaryLight = Color(0xFF90CCDD);
  static const Color navy = Color(0xFF05708D);
  static const Color white = Color(0xFFFFFFFF);

  // Neutrals
  static const Color background = Color(0xFFF7FBFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF6F9);
  static const Color border = Color(0xFFD6E6EE);
  static const Color textPrimary = Color(0xFF0F2F3A);
  static const Color textSecondary = Color(0xFF486A78);
  static const Color textMuted = Color(0xFF7FA1AF);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Dark theme support (still within same palette)
  static const Color darkBackground = Color(0xFF071720);
  static const Color darkSurface = Color(0xFF0B2530);
  static const Color darkSurfaceAlt = Color(0xFF0F2E3B);
  static const Color darkBorder = Color(0xFF1B3C4A);
  static const Color darkTextPrimary = Color(0xFFE6F5FA);
  static const Color darkTextSecondary = Color(0xFF9BC2D1);
}
