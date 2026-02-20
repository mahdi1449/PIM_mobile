import 'package:flutter/material.dart';

class FinancePalette {
  static bool _dark = true;

  static void setDarkMode(bool dark) {
    _dark = dark;
  }

  static bool get isDark => _dark;

  static Color get navy =>
      _dark ? const Color(0xFF050B2D) : const Color(0xFF022946);
  static Color get blue =>
      _dark ? const Color(0xFF2F53FF) : const Color(0xFF0A4977);
  static Color get cyan =>
      _dark ? const Color(0xFF6CC4FF) : const Color(0xFF6CC4FF);
  static Color get ink =>
      _dark ? const Color(0xFFE9EEFF) : const Color(0xFF0F172A);
  static Color get soft =>
      _dark ? const Color(0xFF1A2454) : const Color(0xFFF2F6FB);
  static Color get card =>
      _dark ? const Color(0xFF121A43) : const Color(0xFFFFFFFF);
  static Color get success => const Color(0xFF1FA971);
  static Color get danger => const Color(0xFFE7426C);
  static Color get warning => const Color(0xFFFFA726);
  static Color get scaffold =>
      _dark ? const Color(0xFF070E33) : const Color(0xFFF2F6FB);
  static Color get muted =>
      _dark ? const Color(0xFFAAB5DA) : const Color(0xFF5E6C92);
}

ThemeData buildFinanceLightTheme() {
  return _buildFinanceTheme(brightness: Brightness.light);
}

ThemeData buildFinanceDarkTheme() {
  return _buildFinanceTheme(brightness: Brightness.dark);
}

ThemeData _buildFinanceTheme({required Brightness brightness}) {
  const base = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: FinancePalette.scaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FinancePalette.blue,
      brightness: brightness,
      primary: FinancePalette.blue,
      secondary: FinancePalette.cyan,
      surface: FinancePalette.card,
      error: FinancePalette.danger,
      onPrimary: Colors.white,
      onSurface: FinancePalette.ink,
    ),
    textTheme: base.apply(
      bodyColor: FinancePalette.ink,
      displayColor: FinancePalette.ink,
      fontFamily: 'Poppins',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: FinancePalette.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FinancePalette.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FinancePalette.soft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FinancePalette.soft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: FinancePalette.blue, width: 1.5),
      ),
    ),
  );
}
