import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunicationPalette {
  static bool _dark = true;

  static void setDarkMode(bool dark) {
    _dark = dark;
  }

  static bool _isDark(BuildContext? context) {
    if (context != null) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return _dark;
  }

  static const Color primary = Color(0xFF4B8DFF);
  static const Color primarySoft = Color(0xFF84AEFF);
  static const Color secondary = Color(0xFF55E3DB);
  static const Color accent = Color(0xFF67F3E9);

  static const Color scaffoldBlue = Color(0xFF03132A);
  static const Color deepBlue = Color(0xFF041B3B);
  static const Color cardBlue = Color(0xFF122845);
  static const Color cardBlueSoft = Color(0xFF1C3555);
  static const Color textWhite = Color(0xFFDCE8FF);
  static const Color textMutedBlue = Color(0xFF7B8DAA);
  static const Color borderBlue = Color(0xFF2A3D5F);

  static const Color scaffoldLight = Color(0xFFF4F7FF);
  static const Color deepBlueLight = Color(0xFFEAF1FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardLightSoft = Color(0xFFF4F7FF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFDCE5F5);

  static Color scaffold(BuildContext context) {
    return _isDark(context) ? scaffoldBlue : scaffoldLight;
  }

  static Color card(BuildContext context) {
    return _isDark(context) ? cardBlue : cardLight;
  }

  static Color textPrimary(BuildContext context) {
    return _isDark(context) ? textWhite : textDark;
  }

  static Color textMuted(BuildContext context) {
    return _isDark(context) ? textMutedBlue : textMutedLight;
  }

  static Color border(BuildContext context) {
    return _isDark(context) ? borderBlue : borderLight;
  }

  static TextStyle titleStyle({
    double size = 18,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      color: color ?? (_dark ? textWhite : textDark),
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle bodyStyle({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.dmSans(
      color: color ?? (_dark ? textWhite : textDark),
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
    );
  }

  static BoxDecoration glassCard({
    BorderRadius? radius,
    Color? color,
    bool highlight = false,
  }) {
    final dark = _dark;
    final resolvedCard = dark ? cardBlue : cardLight;
    final resolvedBorder = dark ? borderBlue : borderLight;

    return BoxDecoration(
      color: color ??
          (dark
              ? resolvedCard.withValues(alpha: 0.92)
              : resolvedCard.withValues(alpha: 0.96)),
      borderRadius: radius ?? BorderRadius.circular(22),
      border: Border.all(
        color: highlight
            ? secondary.withValues(alpha: dark ? 0.35 : 0.45)
            : resolvedBorder,
        width: highlight ? 1.15 : 0.9,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.18 : 0.06),
          blurRadius: dark ? 22 : 16,
          offset: Offset(0, dark ? 10 : 8),
        ),
      ],
    );
  }

  static BoxDecoration backgroundDecoration() {
    if (_dark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071F46), Color(0xFF031B3E), Color(0xFF02162F)],
          stops: [0, 0.35, 1],
        ),
      );
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5F8FF), Color(0xFFEEF4FF), Color(0xFFE6EEFF)],
        stops: [0, 0.35, 1],
      ),
    );
  }
}
