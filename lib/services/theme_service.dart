import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _themeModeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Reads the saved preference. The app can run on the default theme, so a
  /// storage failure must not stop it from starting.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      _themeMode = ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
      notifyListeners();
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // A failed save only loses the choice after a restart, so the theme stays
    // applied for this session.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }
}
