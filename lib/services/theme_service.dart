import 'package:dziesiatka/models/app_accent.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const _themeModeKey = 'themeMode';
  static const _accentKey = 'themeAccent';

  ThemeMode _themeMode = ThemeMode.system;
  AppAccent _accent = AppAccent.standard;

  ThemeMode get themeMode => _themeMode;

  /// The chosen accent. The app shows it only with Dziesiątka+, so the choice
  /// survives if the purchase is restored later.
  AppAccent get accent => _accent;

  AppAccent accentFor({required bool hasPlus}) {
    return hasPlus || !_accent.needsPlus ? _accent : AppAccent.standard;
  }

  /// Reads the saved preference. The app can run on the default theme, so a
  /// storage failure must not stop it from starting.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      _themeMode = ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
      _accent =
          AppAccent.values.asNameMap()[prefs.getString(_accentKey)] ??
          AppAccent.standard;
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

  Future<void> setAccent(AppAccent accent) async {
    _accent = accent;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accentKey, accent.name);
    } catch (_) {}
  }
}
