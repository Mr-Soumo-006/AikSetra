import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static bool isDarkMode = false;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkMode = prefs.getBool('aiksetra_dark_mode') ?? false;
      themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  static Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('aiksetra_dark_mode', isDarkMode);
    } catch (_) {}
  }

  static Future<void> setDarkMode(bool dark) async {
    isDarkMode = dark;
    themeModeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('aiksetra_dark_mode', isDarkMode);
    } catch (_) {}
  }
}
