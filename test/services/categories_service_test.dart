import 'package:dziesiatka/services/categories_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with the default categories', () async {
    expect(
      await CategoriesService().getCategories(),
      CategoriesService.defaultCategories,
    );
  });

  test('added categories persist across service instances', () async {
    await CategoriesService().addCategory('  Muzyka ');

    final categories = await CategoriesService().getCategories();
    expect(categories.last, 'Muzyka');
    expect(categories, hasLength(6));
  });

  test('adding an existing category keeps its spelling', () async {
    final added = await CategoriesService().addCategory('kosmos');

    expect(added, 'Kosmos');
    expect(await CategoriesService().getCategories(), hasLength(5));
  });
}
