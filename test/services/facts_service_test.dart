import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/fact_source.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stored_facts.dart';

class _FakeSource implements FactSource {
  _FakeSource(this.facts);

  List<Fact> facts;
  Object? error;
  final List<DateTime?> requests = [];

  @override
  Future<List<Fact>> loadFacts({DateTime? changedSince}) async {
    requests.add(changedSince);
    if (error != null) throw error!;
    return facts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const seedSize = 50;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void givenStored(List<Fact> facts) {
    SharedPreferences.setMockInitialValues(storedFacts(facts));
  }

  group('seed asset', () {
    late List<Map<String, dynamic>> seed;

    setUpAll(() async {
      final source = await rootBundle.loadString('assets/data/facts.json');
      seed = (jsonDecode(source) as List<dynamic>).cast<Map<String, dynamic>>();
    });

    test('has 50 facts with unique ids and titles', () {
      expect(seed, hasLength(seedSize));
      expect(seed.map((fact) => fact['id']).toSet(), hasLength(seedSize));
      expect(seed.map((fact) => fact['title']).toSet(), hasLength(seedSize));
    });

    test('every fact has all text fields', () {
      const fields = [
        'title',
        'category',
        'shortText',
        'longText',
        'sourceLabel',
      ];
      for (final fact in seed) {
        for (final field in fields) {
          expect(
            (fact[field] as String).trim(),
            isNotEmpty,
            reason: '${fact['id']}: $field',
          );
        }
      }
    });

    test('source links are web addresses', () {
      final links = seed.map((fact) => fact['sourceUrl']).nonNulls;

      expect(links, hasLength(9));
      expect(links.every((url) => '$url'.startsWith('https://')), isTrue);
    });

    test('keeps content apart from the user\'s state', () {
      for (final fact in seed) {
        expect(fact.containsKey('isRead'), isFalse);
        expect(fact.containsKey('isFavorite'), isFalse);
      }
    });

    test('categories are balanced', () {
      final counts = <String, int>{};
      for (final fact in seed) {
        final category = fact['category'] as String;
        counts[category] = (counts[category] ?? 0) + 1;
      }

      expect(counts, hasLength(5));
      expect(counts.values.every((count) => count == 10), isTrue);
    });

    test('short texts fit a card', () {
      for (final fact in seed) {
        expect(
          (fact['shortText'] as String).length,
          lessThanOrEqualTo(120),
          reason: fact['id'] as String,
        );
      }
    });

    test('every fact has a valid question with 3 different options', () {
      for (final json in seed) {
        final quiz = Fact.fromJson(json).quiz!;

        expect(quiz.options, hasLength(3), reason: json['id'] as String);
        expect(
          quiz.options.toSet(),
          hasLength(3),
          reason: json['id'] as String,
        );
        expect(quiz.correctIndex, inInclusiveRange(0, 2));
        expect(quiz.question, isNotEmpty);
      }
    });

    test('correct answers are not always in the same position', () {
      final positions = seed.map(
        (json) => Fact.fromJson(json).quiz!.correctIndex,
      );

      expect(positions.toSet(), {0, 1, 2});
    });
  });

  test('first run seeds unread facts from the asset', () async {
    final facts = await FactsService().getFacts();

    expect(facts, hasLength(seedSize));
    expect(facts.every((fact) => !fact.isRead), isTrue);
  });

  test('card state survives a new service instance', () async {
    final service = FactsService();
    final facts = await service.getFacts();

    await service.setCardState(
      facts.first.id,
      isRead: true,
      isFavorite: false,
      lastReadAt: DateTime(2026, 11, 2),
    );

    final reloaded = await FactsService().getFacts();
    expect(reloaded.first.isRead, isTrue);
    expect(reloaded.first.lastReadAt, DateTime(2026, 11, 2));
    expect(reloaded.where((fact) => fact.isRead), hasLength(1));
  });

  test('setCardState can clear the read date', () async {
    final service = FactsService();
    final id = (await service.getFacts()).first.id;
    await service.setCardState(
      id,
      isRead: true,
      isFavorite: false,
      lastReadAt: DateTime(2026, 11, 2),
    );

    await service.setCardState(
      id,
      isRead: false,
      isFavorite: false,
      lastReadAt: null,
    );

    expect((await service.getFacts()).first.lastReadAt, isNull);
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
      expect(await FactsService().syncWithSeed(), hasLength(seedSize));
    });

    test('adds facts with new ids', () async {
      final seeded = await FactsService().syncWithSeed();
      givenStored(seeded.take(4).toList());

      final service = FactsService();
      final synced = await service.syncWithSeed();

      expect(synced, hasLength(seedSize));
      expect(synced.map((fact) => fact.id).toSet(), hasLength(seedSize));
      expect(await service.getFacts(), hasLength(seedSize));
    });

    test('keeps read and favorite state', () async {
      final seeded = await FactsService().syncWithSeed();
      final readAt = DateTime(2026, 11, 2, 8);
      givenStored([
        seeded.first.copyWith(
          isRead: true,
          isFavorite: true,
          lastReadAt: readAt,
        ),
      ]);

      final synced = await FactsService().syncWithSeed();

      expect(synced.first.isRead, isTrue);
      expect(synced.first.isFavorite, isTrue);
      expect(synced.first.lastReadAt, readAt);
      expect(synced.where((fact) => fact.isRead), hasLength(1));
    });

    test('refreshes the content of known facts', () async {
      final seeded = await FactsService().syncWithSeed();
      givenStored([seeded.first.copyWith(title: 'Stary tytuł')]);

      final synced = await FactsService().syncWithSeed();

      expect(synced.first.title, seeded.first.title);
    });

    test('gives old stored facts their new fields', () async {
      SharedPreferences.setMockInitialValues({
        'facts':
            '[{"id":"seed-001","title":"Stary","content":"Treść",'
            '"category":"Kosmos","isRead":true,'
            '"createdAt":"2026-01-01T00:00:00.000Z"}]',
      });

      final synced = await FactsService().syncWithSeed();

      expect(synced.first.sourceLabel, isNotEmpty);
      expect(synced.first.quiz, isNotNull);
      expect(synced.first.isRead, isTrue);
    });

    test('keeps facts that are not in the asset', () async {
      final seeded = await FactsService().syncWithSeed();
      givenStored([seeded.first.copyWith(id: 'custom')]);

      final synced = await FactsService().syncWithSeed();

      expect(synced.map((fact) => fact.id), contains('custom'));
      expect(synced, hasLength(seedSize + 1));
    });
  });

  group('migration of the old storage format', () {
    const legacy =
        '[{"id":"seed-001","title":"Stary","shortText":"Z","longText":"R",'
        '"source":"Źródło","category":"Kosmos","isRead":true,'
        '"isFavorite":true,"lastReadAt":"2026-02-03T04:05:06.000",'
        '"createdAt":"2026-01-01T00:00:00.000Z"},'
        '{"id":"seed-002","title":"Nieczytany","shortText":"Z","longText":"R",'
        '"category":"Kosmos","createdAt":"2026-01-01T00:00:00.000Z"}]';

    test('keeps the progress', () async {
      SharedPreferences.setMockInitialValues({'facts': legacy});

      final facts = await FactsService().syncWithSeed();

      final read = facts.firstWhere((fact) => fact.id == 'seed-001');
      expect(read.isRead, isTrue);
      expect(read.isFavorite, isTrue);
      expect(read.lastReadAt, DateTime(2026, 2, 3, 4, 5, 6));
      expect(facts.where((fact) => fact.isRead), hasLength(1));
    });

    test('runs once and clears the old key', () async {
      SharedPreferences.setMockInitialValues({'facts': legacy});
      final service = FactsService();
      await service.getFacts();
      await service.toggleFavorite('seed-001');

      final facts = await FactsService().getFacts();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('facts'), isNull);
      expect(facts.first.isFavorite, isFalse);
    });
  });

  group('syncWithRemote', () {
    Fact remoteFact(
      String id, {
      String title = 'Z serwera',
      DateTime? updatedAt,
      bool isWithdrawn = false,
    }) {
      return Fact(
        id: id,
        title: title,
        category: 'Kosmos',
        shortText: 'Zajawka',
        longText: 'Rozwinięcie',
        sourceLabel: 'Źródło',
        isWithdrawn: isWithdrawn,
        createdAt: DateTime.utc(2026),
        updatedAt: updatedAt ?? DateTime.utc(2026, 11, 2),
      );
    }

    test('does nothing without a remote source', () async {
      await FactsService().syncWithRemote();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('adds new facts without touching the progress', () async {
      final seedOnly = FactsService();
      final first = (await seedOnly.getFacts()).first;
      await seedOnly.toggleFavorite(first.id);

      await FactsService(
        remote: _FakeSource([remoteFact('remote-1')]),
      ).syncWithRemote();

      final facts = await FactsService().getFacts();
      expect(facts, hasLength(seedSize + 1));
      expect(facts.last.id, 'remote-1');
      expect(facts.first.isFavorite, isTrue);
    });

    test('a newer server copy replaces the text and keeps state', () async {
      final seedOnly = FactsService();
      final first = (await seedOnly.getFacts()).first;
      await seedOnly.toggleFavorite(first.id);

      await FactsService(
        remote: _FakeSource([remoteFact(first.id)]),
      ).syncWithRemote();

      final updated = (await FactsService().getFacts()).first;
      expect(updated.title, 'Z serwera');
      expect(updated.isFavorite, isTrue);
    });

    test('the seed does not undo a newer server copy', () async {
      final first = (await FactsService().getFacts()).first;
      await FactsService(
        remote: _FakeSource([remoteFact(first.id)]),
      ).syncWithRemote();

      final facts = await FactsService().syncWithSeed();

      expect(facts.first.title, 'Z serwera');
    });

    test('asks only for what changed since the last download', () async {
      await FactsService().getFacts();
      final latest = DateTime.utc(2026, 11, 3);
      final source = _FakeSource([
        remoteFact('a', updatedAt: DateTime.utc(2026, 11, 1)),
        remoteFact('b', updatedAt: latest),
      ]);
      final service = FactsService(remote: source);

      await service.syncWithRemote();
      await service.syncWithRemote();

      expect(source.requests, [null, latest]);
    });

    test('a failed download changes nothing and is tried again', () async {
      final before = await FactsService().getFacts();
      final source = _FakeSource([remoteFact('a')])..error = StateError('sieć');
      final service = FactsService(remote: source);

      await expectLater(service.syncWithRemote(), throwsStateError);
      expect(await service.getFacts(), hasLength(before.length));

      source.error = null;
      await service.syncWithRemote();

      expect(source.requests, [null, null]);
      expect(await service.getFacts(), hasLength(before.length + 1));
    });

    test('a withdrawn fact stays stored with its state', () async {
      final seedOnly = FactsService();
      final first = (await seedOnly.getFacts()).first;
      await seedOnly.toggleFavorite(first.id);

      await FactsService(
        remote: _FakeSource([remoteFact(first.id, isWithdrawn: true)]),
      ).syncWithRemote();

      final stored = (await FactsService().getFacts()).first;
      expect(stored.isWithdrawn, isTrue);
      expect(stored.isFavorite, isTrue);
    });
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
