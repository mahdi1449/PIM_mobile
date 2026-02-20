import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:odin/admin_web/admin_web.dart';
import 'package:odin/finance/finance.dart';
import 'package:odin/user_management/user_management.dart';

void main() {
  runApp(const OdinFinanceApp());
}

class OdinFinanceApp extends StatefulWidget {
  const OdinFinanceApp({super.key});

  @override
  State<OdinFinanceApp> createState() => _OdinFinanceAppState();
}

class _OdinFinanceAppState extends State<OdinFinanceApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final isDark = _themeMode == ThemeMode.dark;
    AdminPalette.setDarkMode(isDark);
    FinancePalette.setDarkMode(isDark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isWeb ? 'Football ERP Admin Web' : 'Football ERP User App',
      themeMode: _themeMode,
      theme: isWeb ? buildAdminWebLightTheme() : buildFinanceLightTheme(),
      darkTheme: isWeb ? buildAdminWebDarkTheme() : buildFinanceDarkTheme(),
      home: isWeb
          ? AdminWebShell(onToggleTheme: _toggleTheme)
          : const MobileUserApp(),
    );
  }
}
