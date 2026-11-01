import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the categories the user took off their favorites. All are
/// favorites until then, and so is a category added later.
class CategoryPreferencesService {
  const CategoryPreferencesService();

  /// A smaller choice would soon run out of new facts.
  static const minFavorites = 3;
  static const _disabledKey = 'disabledCategories';

  Future<Set<String>> getDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_disabledKey) ?? const []).toSet();
  }

  /// Replaces the whole choice, which the first-run screen makes at once.
  Future<void> saveFavorites(
    Set<String> favorites, {
    required List<String> allCategories,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _disabledKey,
      allCategories.where((name) => !favorites.contains(name)).toList(),
    );
  }

  Future<void> setEnabled(String category, {required bool isEnabled}) async {
    final disabled = await getDisabled();
    isEnabled ? disabled.remove(category) : disabled.add(category);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_disabledKey, disabled.toList());
  }
}
