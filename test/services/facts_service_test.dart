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

  test('toggleFavorite switches the flag and persists it', () async {
    final service = FactsService();
    final facts = await service.getFacts();

    await service.toggleFavorite(facts.first.id);
    final favorite = await FactsService().getFacts();
    expect(favorite.first.isFavorite, isTrue);
    expect(favorite.where((fact) => fact.isFavorite), hasLength(1));

    await service.toggleFavorite(facts.first.id);
    final cleared = await FactsService().getFacts();
    expect(cleared.first.isFavorite, isFalse);
  });

  group('syncWithSeed', () {
    test('fills empty storage from the asset', () async {
      expect(await FactsService().syncWithSeed(), hasLength(10));
    });

    test('adds only facts with new ids', () async {
      final service = FactsService();
      final seeded = await service.syncWithSeed();
      await service.replaceFacts(seeded.take(4).toList());

      final synced = await service.syncWithSeed();

      expect(synced, hasLength(10));
      expect(synced.map((fact) => fact.id).toSet(), hasLength(10));
      expect(await service.getFacts(), hasLength(10));
    });

    test('keeps read and favorite state and local edits', () async {
      final service = FactsService();
      final seeded = await service.syncWithSeed();
      await service.setCardState(
        seeded.first.id,
        isRead: true,
        isFavorite: true,
      );
      await service.replaceFacts([
        (await service.getFacts()).first.copyWith(title: 'Zmieniony'),
      ]);

      final synced = await service.syncWithSeed();

      expect(synced.first.isRead, isTrue);
      expect(synced.first.isFavorite, isTrue);
      expect(synced.first.title, 'Zmieniony');
    });

    test('keeps facts that are not in the asset', () async {
      final service = FactsService();
      final added = await service.addFact(
        title: 'Nowa',
        category: 'Historia',
        shortText: 'Zajawka',
        longText: 'Rozwinięcie',
        source: 'Źródło',
      );

      final synced = await service.syncWithSeed();

      expect(synced.map((fact) => fact.id), contains(added.id));
    });
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
