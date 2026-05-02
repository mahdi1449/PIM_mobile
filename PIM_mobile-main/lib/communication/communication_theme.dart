import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunicationPalette {
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

  static Color scaffold(BuildContext context) {
    return scaffoldBlue;
  }

  static Color card(BuildContext context) {
    return cardBlue;
  }

  static Color textPrimary(BuildContext context) {
    return textWhite;
  }

  static Color textMuted(BuildContext context) {
    return textMutedBlue;
  }

  static Color border(BuildContext context) {
    return borderBlue;
  }

  static TextStyle titleStyle({
    double size = 18,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.spaceGrotesk(
      color: color ?? textWhite,
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
      color: color ?? textWhite,
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
    return BoxDecoration(
      color: color ?? cardBlue.withValues(alpha: 0.92),
      borderRadius: radius ?? BorderRadius.circular(22),
      border: Border.all(
        color: highlight ? secondary.withValues(alpha: 0.35) : borderBlue,
        width: highlight ? 1.15 : 0.9,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration backgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF071F46), Color(0xFF031B3E), Color(0xFF02162F)],
        stops: [0, 0.35, 1],
      ),
    );
  }
}
