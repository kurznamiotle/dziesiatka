import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'first run seeds 10 unread facts with unique ids from the asset',
    () async {
      final facts = await FactsService().getFacts();

      expect(facts, hasLength(10));
      expect(facts.every((fact) => !fact.isRead), isTrue);
      expect(facts.map((fact) => fact.id).toSet(), hasLength(10));
      expect(facts.map((fact) => fact.category).toSet(), hasLength(5));
    },
  );

  test('read state survives a new service instance', () async {
    final service = FactsService();
    final facts = await service.getFacts();

    await service.markAsRead(facts.first.id);

    final reloaded = await FactsService().getFacts();
    expect(reloaded.first.isRead, isTrue);
    expect(reloaded.where((fact) => fact.isRead), hasLength(1));
  });

  test('resetReadState clears read state and keeps added facts', () async {
    final service = FactsService();
    final facts = await service.getFacts();
    await service.markAsRead(facts.first.id);
    await service.addFact(
      title: 'Nowa',
      category: 'Historia',
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      source: 'Źródło',
    );

    await service.resetReadState();

    final reloaded = await FactsService().getFacts();
    expect(reloaded, hasLength(11));
    expect(reloaded.every((fact) => !fact.isRead), isTrue);
  });

  test('added facts are stored and not replaced by the seed', () async {
    final service = FactsService();

    final added = await service.addFact(
      title: 'Nowa',
      category: 'Historia',
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      source: 'Źródło',
    );

    final reloaded = await FactsService().getFacts();
    expect(reloaded, hasLength(11));
    expect(reloaded.last.id, added.id);
    expect(reloaded.last.isRead, isFalse);
  });

  test('every seeded fact has short text, long text and a source', () async {
    final facts = await FactsService().getFacts();

    for (final fact in facts) {
      expect(fact.shortText, isNotEmpty);
      expect(fact.longText, isNotEmpty);
      expect(fact.source, isNotEmpty);
    }
  });

  test('deleted facts stay deleted after reloading', () async {
    final service = FactsService();
    final facts = await service.getFacts();

    await service.deleteFact(facts.first.id);

    final reloaded = await FactsService().getFacts();
    expect(reloaded, hasLength(9));
    expect(reloaded.map((fact) => fact.id), isNot(contains(facts.first.id)));
  });

  test('old facts in storage still load', () async {
    SharedPreferences.setMockInitialValues({
      'facts':
          '[{"id":"seed-001","title":"Stary","content":"Treść",'
          '"category":"Kosmos","isRead":true,'
          '"createdAt":"2026-01-01T00:00:00.000Z"}]',
    });

    final facts = await FactsService().getFacts();

    expect(facts.single.shortText, 'Treść');
    expect(facts.single.isRead, isTrue);
  });
}
