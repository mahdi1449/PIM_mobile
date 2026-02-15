import 'package:flutter/material.dart';
import 'theme_controller.dart';

class AppTheme {
  // Dark neo-dashboard palette (inspired by provided reference)
  static const Color _darkBackground = Color(0xFF0B0D12);
  static const Color _darkSurface = Color(0xFF1B1F27);
  static const Color _darkSurfaceAlt = Color(0xFF12151C);
  static const Color _darkPrimary = Color(0xFF2B56FF);
  static const Color _darkSecondary = Color(0xFF4C6BFF);
  static const Color _darkText = Color(0xFFEDEFF4);
  static const Color _darkSubtext = Color(0xFF9AA0A8);
  static const Color _darkOutline = Color(0xFF2A2F39);

  // Light palette (original brand colors)
  static const Color _lightPrimary = Color(0xFF1E3A5F);
  static const Color _lightSecondary = Color(0xFF87CEEB);
  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF424242);
  static const Color _lightOutline = Color(0xFFE1E5EE);

  static const Color accentOrange = Color(0xFFFF6A3D);
  static const Color accentGreen = Color(0xFF35D07F);

  static bool get _isDark => ThemeController.mode.value == ThemeMode.dark;

  // Dynamic palette accessors
  static Color get blueFonce => _isDark ? _darkText : _lightPrimary;
  static Color get blueCiel => _isDark ? _darkPrimary : _lightSecondary;
  static Color get odinDarkBlue => _isDark ? _darkSurfaceAlt : _lightPrimary;
  static Color get odinSkyBlue => _isDark ? _darkSecondary : _lightSecondary;
  static Color get white => _isDark ? _darkSurface : _lightSurface;
  static Color get lightGrey => _isDark ? _darkBackground : _lightBackground;
  static Color get darkGrey => _isDark ? _darkSubtext : _lightText;
  static Color get strokeDark => _isDark ? _darkOutline : _lightOutline;

  // Legacy support (keeping for compatibility)
  static Color get primaryGreen => blueFonce;
  static Color get lightGreen => blueCiel;
  static const Color darkGreen = Color(0xFF0D1118);

  // Gradient decoration
  static BoxDecoration get gradientDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [
                  _darkBackground,
                  _darkSurfaceAlt,
                  _darkSurface,
                ]
              : [
                  _lightSurface,
                  _lightSecondary.withOpacity(0.3),
                  _lightPrimary.withOpacity(0.1),
                ],
        ),
      );

  // Button gradient
  static BoxDecoration get buttonGradient => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [_darkSecondary, _darkPrimary]
              : [_lightPrimary, _lightSecondary],
        ),
        borderRadius: BorderRadius.circular(12),
      );

  // Theme data
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _lightPrimary,
          brightness: Brightness.light,
          primary: _lightPrimary,
          secondary: _lightSecondary,
          surface: _lightSurface,
          background: _lightBackground,
          onSurface: _lightText,
          onBackground: _lightText,
          outline: _lightOutline,
        ),
        scaffoldBackgroundColor: _lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightSurface,
          foregroundColor: _lightPrimary,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _lightPrimary,
            foregroundColor: _lightSurface,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: _lightSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _lightOutline),
          ),
        ),
        iconTheme: const IconThemeData(color: _lightPrimary),
        dividerColor: _lightOutline,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lightSurface,
          selectedItemColor: _lightPrimary,
          unselectedItemColor: _lightText,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _lightText,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _lightText,
            letterSpacing: -0.2,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: _lightText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: _lightText,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _lightText,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _darkPrimary,
          brightness: Brightness.dark,
          primary: _darkPrimary,
          secondary: _darkSecondary,
          surface: _darkSurface,
          background: _darkBackground,
          onSurface: _darkText,
          onBackground: _darkText,
          outline: _darkOutline,
        ),
        scaffoldBackgroundColor: _darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkSurfaceAlt,
          foregroundColor: _darkText,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkPrimary,
            foregroundColor: _darkText,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: _darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _darkOutline),
          ),
        ),
        iconTheme: const IconThemeData(color: _darkText),
        dividerColor: _darkOutline,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkSurfaceAlt,
          selectedItemColor: _darkPrimary,
          unselectedItemColor: _darkSubtext,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _darkText,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _darkText,
            letterSpacing: -0.2,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: _darkText,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: _darkSubtext,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
      );
}
