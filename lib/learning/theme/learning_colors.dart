import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_theme.dart';

class LearningColors {
  LearningColors._();

  // Use the main ODIN app palette so the learning module matches the rest of the application.
  // (You can later swap these to a dedicated learning accent color if needed.)
  static Color get lime => AppTheme.primaryBlue;
  static Color get limeDark => AppTheme.blueFonce;
  static const Color navy = Color(0xFF0B1220);
  static const Color navy2 = Color(0xFF121B2D);
  static Color get surface => AppTheme.background;
  static Color get card => AppTheme.surface;
  static Color get text => AppTheme.textPrimary;
  static Color get textMuted => AppTheme.textMuted;
  static Color get border => AppTheme.cardBorder;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
}
