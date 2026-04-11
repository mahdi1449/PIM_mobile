import 'package:flutter/material.dart';
import '../../finance/theme/finance_theme.dart';
import '../../ui/theme/staff_technique_hub.dart';

class AnalysisPalette {
  static void setDarkMode(bool dark) {
    FinancePalette.setDarkMode(dark);
  }

  static Color get bgTop => FinancePalette.isDark
      ? const Color(0xFF0B2931)
      : StaffTechniqueHubTheme.background;
  static Color get bgBottom =>
      FinancePalette.isDark ? const Color(0xFF16414D) : const Color(0xFFE7F4F8);
  static Color get panel => FinancePalette.isDark
      ? const Color(0xFF123844)
      : StaffTechniqueHubTheme.surface;
  static Color get panel2 => FinancePalette.isDark
      ? const Color(0xFF184653)
      : StaffTechniqueHubTheme.surfaceSoft;
  static Color get border => FinancePalette.isDark
      ? const Color(0xFF2B5D69)
      : StaffTechniqueHubTheme.border;
  static Color get neonBlue => StaffTechniqueHubTheme.primary;
  static Color get electric => StaffTechniqueHubTheme.primary;
  static Color get cyan => StaffTechniqueHubTheme.secondary;
  static Color get violet => Color.lerp(
    StaffTechniqueHubTheme.primary,
    StaffTechniqueHubTheme.secondary,
    0.5,
  )!;
  static Color get mint =>
      FinancePalette.isDark ? const Color(0xFF61C7AE) : const Color(0xFF2C8B79);
  static Color get text => FinancePalette.isDark
      ? const Color(0xFFF2FBFC)
      : StaffTechniqueHubTheme.textPrimary;
  static Color get muted => FinancePalette.isDark
      ? const Color(0xFFA1C1C8)
      : StaffTechniqueHubTheme.textSecondary;
  static Color get softLine => border;
  static Color get danger => FinancePalette.danger;
  static Color get warning => FinancePalette.warning;
  static Color get overlayCard =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.86 : 0.94);
  static Color get elevatedStroke => neonBlue.withValues(alpha: 0.26);
  static Color get elevatedGlow => neonBlue.withValues(alpha: 0.18);
  static Color get ringBase =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.75 : 0.9);
  static Color get chipFill =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.95 : 1);
  static Color get chipBorder => softLine;
  static Color get softTrack =>
      softLine.withValues(alpha: FinancePalette.isDark ? 0.85 : 0.55);
  static Color get dangerSoft =>
      danger.withValues(alpha: FinancePalette.isDark ? 0.18 : 0.1);
  static Color get errorBannerBg =>
      FinancePalette.isDark ? const Color(0xFF17141F) : const Color(0xFFFFF3F6);
  static Color get pitchGrassTop =>
      FinancePalette.isDark ? const Color(0xFF1C4A40) : const Color(0xFF2A7565);
  static Color get pitchGrassBottom =>
      FinancePalette.isDark ? const Color(0xFF0D261F) : const Color(0xFF174E43);
  static Color get pitchLine =>
      FinancePalette.isDark ? const Color(0x66E6FFF2) : const Color(0x88F4FFFB);
  static Color get ringTrackBase =>
      panel2.withValues(alpha: FinancePalette.isDark ? 0.9 : 0.65);
  static Color get blackChip =>
      FinancePalette.isDark ? const Color(0xFF121212) : const Color(0xFF2A2A2A);
}

BoxDecoration analysisShellDecoration() {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AnalysisPalette.bgTop, AnalysisPalette.bgBottom],
    ),
  );
}

TextStyle neonSectionStyle() => TextStyle(
  color: AnalysisPalette.neonBlue,
  fontSize: 13,
  letterSpacing: 2.2,
  fontWeight: FontWeight.w700,
);

BoxDecoration glowPanelDecoration({double radius = 24, bool withGlow = false}) {
  return BoxDecoration(
    color: AnalysisPalette.panel,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AnalysisPalette.softLine),
    boxShadow: withGlow
        ? [
            BoxShadow(
              color: AnalysisPalette.neonBlue.withValues(alpha: 0.22),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ]
        : [],
  );
}
