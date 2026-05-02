import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const _storageKey = 'odin_theme_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    mode.value = stored == ThemeMode.light.name
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  static Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, value.name);
  }

  static Future<void> toggle() {
    return setMode(
      mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
