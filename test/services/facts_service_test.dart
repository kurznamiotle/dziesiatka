import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const seedSize = 50;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void givenStored(List<Fact> facts) {
    final encoded = jsonEncode(facts.map((fact) => fact.toJson()).toList());
    SharedPreferences.setMockInitialValues({'facts': encoded});
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
      const fields = ['title', 'category', 'shortText', 'longText', 'source'];
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

    await service.setCardState(facts.first.id, isRead: true, isFavorite: false);

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
      givenStored([seeded.first.copyWith(isRead: true, isFavorite: true)]);

      final synced = await FactsService().syncWithSeed();

      expect(synced.first.isRead, isTrue);
      expect(synced.first.isFavorite, isTrue);
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

      expect(synced.first.source, isNotEmpty);
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
