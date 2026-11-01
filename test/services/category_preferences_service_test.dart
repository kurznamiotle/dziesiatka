import 'package:dziesiatka/services/category_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = CategoryPreferencesService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('all categories are on at first', () async {
    expect(await service.getDisabled(), isEmpty);
  });

  test('a category turned off stays off until turned on', () async {
    await service.setEnabled('Kosmos', isEnabled: false);
    expect(await service.getDisabled(), {'Kosmos'});

    await service.setEnabled('Kosmos', isEnabled: true);
    expect(await service.getDisabled(), isEmpty);
  });
}
