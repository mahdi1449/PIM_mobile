import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/theme_controller.dart';

class MedicalTheme {
  MedicalTheme._();

  static bool get _isDark => ThemeController.mode.value == ThemeMode.dark;

  static const Color _lightBackground = Color(0xFFF5F8FD);
  static const Color _lightBackgroundSoft = Color(0xFFE9F0FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceAlt = Color(0xFFF1F5FC);
  static const Color _lightCardBorder = Color(0xFFD9E3F0);
  static const Color _lightPrimaryBlue = Color(0xFF2F6BFF);
  static const Color _lightAccentBlue = Color(0xFF3D8CFF);
  static const Color _lightAccentTeal = Color(0xFF1CB6B0);
  static const Color _lightTextPrimary = Color(0xFF0F1D33);
  static const Color _lightTextSecondary = Color(0xFF5B6B82);
  static const Color _lightTextMuted = Color(0xFF93A3B8);

  static const Color _darkBackground = Color(0xFF050816);
  static const Color _darkBackgroundSoft = Color(0xFF0B1023);
  static const Color _darkSurface = Color(0xFF111936);
  static const Color _darkSurfaceAlt = Color(0xFF16213E);
  static const Color _darkCardBorder = Color(0xFF2A3A63);
  static const Color _darkPrimaryBlue = Color(0xFF5B4DFF);
  static const Color _darkAccentBlue = Color(0xFF6D5DFF);
  static const Color _darkAccentTeal = Color(0xFF2DD4BF);
  static const Color _darkTextPrimary = Color(0xFFFFFFFF);
  static const Color _darkTextSecondary = Color(0xFFA5B4FC);
  static const Color _darkTextMuted = Color(0xFF94A3B8);

  static Color get background => _isDark ? _darkBackground : _lightBackground;
  static Color get backgroundSoft =>
      _isDark ? _darkBackgroundSoft : _lightBackgroundSoft;
  static Color get surface => _isDark ? _darkSurface : _lightSurface;
  static Color get surfaceAlt => _isDark ? _darkSurfaceAlt : _lightSurfaceAlt;
  static Color get card => surface;
  static Color get cardBorder => _isDark ? _darkCardBorder : _lightCardBorder;

  static Color get primaryBlue =>
      _isDark ? _darkPrimaryBlue : _lightPrimaryBlue;
  static Color get accentBlue => _isDark ? _darkAccentBlue : _lightAccentBlue;
  static Color get accentTeal => _isDark ? _darkAccentTeal : _lightAccentTeal;

  static Color get textPrimary =>
      _isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get textMuted => _isDark ? _darkTextMuted : _lightTextMuted;

  static const Color success = Color(0xFF1AAE7C);
  static const Color warning = Color(0xFFF3A43B);
  static const Color danger = Color(0xFFE15759);

  static LinearGradient get appGradient {
    if (_isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_darkBackground, _darkBackgroundSoft],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_lightBackground, _lightBackgroundSoft],
    );
  }

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: _isDark ? 0.24 : 0.06),
      blurRadius: _isDark ? 26 : 24,
      offset: Offset(0, _isDark ? 14 : 12),
    ),
  ];

  static BoxDecoration cardDecoration({double radius = 18}) => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cardBorder),
    boxShadow: softShadow,
  );

  static BoxDecoration softCardDecoration({double radius = 16}) =>
      BoxDecoration(
        color: surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder),
      );

  static TextTheme themedText(TextTheme base) {
    final textTheme = GoogleFonts.manropeTextTheme(base);
    return textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: textTheme.bodyMedium?.copyWith(color: textSecondary),
      bodySmall: textTheme.bodySmall?.copyWith(color: textMuted),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(color: textSecondary),
      labelSmall: textTheme.labelSmall?.copyWith(color: textSecondary),
    );
  }

  static ThemeData theme(ThemeData base) {
    final textTheme = themedText(base.textTheme);
    final isDark = base.brightness == Brightness.dark;
    return base.copyWith(
      scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: isDark ? _darkPrimaryBlue : _lightPrimaryBlue,
        secondary: isDark ? _darkAccentTeal : _lightAccentTeal,
        surface: isDark ? _darkSurface : _lightSurface,
        background: isDark ? _darkBackground : _lightBackground,
        onSurface: isDark ? _darkTextPrimary : _lightTextPrimary,
        onBackground: isDark ? _darkTextPrimary : _lightTextPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: cardBorder),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 1.4),
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: surface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }
}

// Compatibility shim for medical screens still referencing AppTheme.
class AppTheme {
  AppTheme._();

  static Color get background => MedicalTheme.background;
  static Color get surface => MedicalTheme.surface;
  static Color get surfaceAlt => MedicalTheme.surfaceAlt;
  static Color get card => MedicalTheme.card;
  static Color get cardBorder => MedicalTheme.cardBorder;
  static Color get primaryBlue => MedicalTheme.primaryBlue;
  static Color get accentBlue => MedicalTheme.accentBlue;
  static Color get textPrimary => MedicalTheme.textPrimary;
  static Color get textSecondary => MedicalTheme.textSecondary;
  static Color get textMuted => MedicalTheme.textMuted;
  static Color get success => MedicalTheme.success;
  static Color get warning => MedicalTheme.warning;
  static Color get danger => MedicalTheme.danger;

  static LinearGradient get appGradient => MedicalTheme.appGradient;
}

class MedicalThemeScope extends StatelessWidget {
  const MedicalThemeScope({
    super.key,
    required this.child,
    this.applyBackground = true,
  });

  final Widget child;
  final bool applyBackground;

  @override
  Widget build(BuildContext context) {
    final themed = MedicalTheme.theme(Theme.of(context));
    Widget content = child;

    if (applyBackground) {
      content = DecoratedBox(
        decoration: BoxDecoration(gradient: MedicalTheme.appGradient),
        child: content,
      );
    }

    return Theme(
      data: themed,
      child: DefaultTextStyle(
        style: themed.textTheme.bodyMedium ?? const TextStyle(),
        child: content,
      ),
    );
  }
}
