import 'package:shared_preferences/shared_preferences.dart';

class CategoriesService {
  static const _categoriesKey = 'categories';
  static const defaultCategories = [
    'Kosmos',
    'Zwierzęta',
    'Historia',
    'Psychologia',
    'Technologia',
  ];

  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey) ?? defaultCategories;
  }

  /// Saves [name] and returns the stored spelling, which is the existing one
  /// when the category already exists under a different letter case.
  Future<String> addCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    final trimmed = name.trim();
    final normalized = trimmed.toLowerCase();

    for (final category in categories) {
      if (category.toLowerCase() == normalized) return category;
    }

    await prefs.setStringList(_categoriesKey, [...categories, trimmed]);
    return trimmed;
  }

  Future<void> replaceCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }
}
