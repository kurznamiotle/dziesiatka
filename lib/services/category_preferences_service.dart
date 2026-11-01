import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the categories the user turned off. Keeping the turned-off ones
/// means a category added later is on by default.
class CategoryPreferencesService {
  const CategoryPreferencesService();

  static const _disabledKey = 'disabledCategories';

  Future<Set<String>> getDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_disabledKey) ?? const []).toSet();
  }

  Future<void> setEnabled(String category, {required bool isEnabled}) async {
    final disabled = await getDisabled();
    isEnabled ? disabled.remove(category) : disabled.add(category);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_disabledKey, disabled.toList());
  }
}
