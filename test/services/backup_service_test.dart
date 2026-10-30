import 'package:dziesiatka/services/backup_service.dart';
import 'package:dziesiatka/services/categories_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FactsService facts;
  late CategoriesService categories;
  late BackupService backup;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    facts = FactsService();
    categories = CategoriesService();
    backup = BackupService(facts, categories);
  });

  test('an export restores read state, added facts and categories', () async {
    final seeded = await facts.getFacts();
    await facts.markAsRead(seeded.first.id);
    await categories.addCategory('Muzyka');
    final added = await facts.addFact(
      title: 'Nowa',
      category: 'Muzyka',
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      source: 'Źródło',
    );
    final exported = await backup.exportJson();

    await facts.replaceFacts([]);
    await categories.replaceCategories([]);
    await backup.restore(backup.parse(exported));

    final restored = await facts.getFacts();
    expect(restored, hasLength(11));
    expect(restored.first.isRead, isTrue);
    expect(restored.last.id, added.id);
    expect(await categories.getCategories(), contains('Muzyka'));
  });

  test('an imported empty database is not reseeded', () async {
    await backup.restore(backup.parse('{"categories": [], "facts": []}'));

    expect(await facts.getFacts(), isEmpty);
  });

  test('parse rejects text that is not a database export', () {
    expect(() => backup.parse('nie json'), throwsFormatException);
    expect(() => backup.parse('[]'), throwsFormatException);
    expect(() => backup.parse('{}'), throwsFormatException);
  });
}
