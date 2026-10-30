import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first run seeds 10 unread facts with unique ids from the asset', () async {
    final facts = await FactsService().getFacts();

    expect(facts, hasLength(10));
    expect(facts.every((fact) => !fact.isRead), isTrue);
    expect(facts.map((fact) => fact.id).toSet(), hasLength(10));
    expect(facts.map((fact) => fact.category).toSet(), hasLength(5));
  });

  test('read state survives a new service instance', () async {
    final service = FactsService();
    final facts = await service.getFacts();

    await service.markAsRead(facts.first.id);

    final reloaded = await FactsService().getFacts();
    expect(reloaded.first.isRead, isTrue);
    expect(reloaded.where((fact) => fact.isRead), hasLength(1));
  });

  test('added facts are stored and not replaced by the seed', () async {
    final service = FactsService();

    final added = await service.addFact(
      title: 'Nowa',
      content: 'Treść',
      category: 'Historia',
    );

    final reloaded = await FactsService().getFacts();
    expect(reloaded, hasLength(11));
    expect(reloaded.last.id, added.id);
    expect(reloaded.last.isRead, isFalse);
  });
}
