import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/daily_deck_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FactsService facts;
  late DateTime now;
  late DailyDeckService service;

  DailyDeckService newService() => DailyDeckService(facts, now: () => now);

  Fact fact(int number, {bool isRead = false, bool isFavorite = false}) {
    return Fact(
      id: 'fact-$number',
      title: 'Fakt $number',
      category: 'Kosmos',
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      source: 'Źródło',
      isRead: isRead,
      isFavorite: isFavorite,
      createdAt: DateTime.utc(2026),
    );
  }

  Future<Fact> stored(String id) async {
    return (await facts.getFacts()).firstWhere((fact) => fact.id == id);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    facts = FactsService();
    now = DateTime(2026, 11, 2, 12);
    service = newService();
  });

  group('choosing a deck', () {
    test('takes exactly 10 facts, unread ones first', () async {
      await facts.replaceFacts([
        for (var i = 0; i < 30; i++) fact(i, isRead: i < 5),
      ]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(DailyDeckService.deckSize));
      expect(session.facts.first.id, 'fact-5');
      expect(session.facts.every((fact) => !fact.isRead), isTrue);
    });

    test('fills the deck with read facts when unread ones run out', () async {
      await facts.replaceFacts([
        for (var i = 0; i < 12; i++) fact(i, isRead: i >= 3),
      ]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(10));
      expect(session.facts.take(3).every((fact) => !fact.isRead), isTrue);
      expect(session.facts.skip(3).every((fact) => fact.isRead), isTrue);
      expect(session.facts.map((fact) => fact.id).toSet(), hasLength(10));
    });

    test('uses the whole pool when it has fewer than 10 facts', () async {
      await facts.replaceFacts([for (var i = 0; i < 4; i++) fact(i)]);

      expect((await service.loadToday()).facts, hasLength(4));
    });

    test('repeated cards change from day to day', () async {
      await facts.replaceFacts([
        for (var i = 0; i < 20; i++) fact(i, isRead: true),
      ]);

      final first = await service.loadToday();
      now = now.add(const Duration(days: 1));
      final second = await service.loadToday();

      expect(first.facts.first.id, isNot(second.facts.first.id));
    });
  });

  group('during the day', () {
    test('the same deck comes back after a restart', () async {
      await facts.replaceFacts([for (var i = 0; i < 20; i++) fact(i)]);
      final first = await service.loadToday();
      await facts.markAsRead('fact-0');

      final second = await newService().loadToday();

      expect(
        second.facts.map((fact) => fact.id),
        first.facts.map((fact) => fact.id),
      );
    });

    test('completing a repeated fact counts toward today', () async {
      await facts.replaceFacts([
        for (var i = 0; i < 10; i++) fact(i, isRead: true),
      ]);

      final session = await service.completeCard('fact-0', liked: false);

      expect(session.completedCount, 1);
      expect(session.remaining, hasLength(9));
    });

    test('a like sets the favorite flag and marks the fact read', () async {
      await facts.replaceFacts([fact(0)]);

      await service.completeCard('fact-0', liked: true);

      final saved = await stored('fact-0');
      expect(saved.isFavorite, isTrue);
      expect(saved.isRead, isTrue);
    });

    test('moving on keeps an existing favorite', () async {
      await facts.replaceFacts([fact(0, isFavorite: true)]);

      await service.completeCard('fact-0', liked: false);

      expect((await stored('fact-0')).isFavorite, isTrue);
    });

    test('a card outside the remaining ones is ignored', () async {
      await facts.replaceFacts([fact(0), fact(1)]);
      await service.completeCard('fact-0', liked: false);

      final session = await service.completeCard('fact-0', liked: true);

      expect(session.completedCount, 1);
      expect((await stored('fact-0')).isFavorite, isFalse);
    });
  });

  group('undo', () {
    test('restores a card and its earlier state', () async {
      await facts.replaceFacts([fact(0), fact(1)]);
      await service.completeCard('fact-0', liked: true);

      final session = await service.undo();

      expect(session.remaining.first.id, 'fact-0');
      final saved = await stored('fact-0');
      expect(saved.isFavorite, isFalse);
      expect(saved.isRead, isFalse);
    });

    test('keeps a fact read or favorite from before the swipe', () async {
      await facts.replaceFacts([fact(0, isRead: true, isFavorite: true)]);
      await service.completeCard('fact-0', liked: true);

      await service.undo();

      final saved = await stored('fact-0');
      expect(saved.isRead, isTrue);
      expect(saved.isFavorite, isTrue);
    });

    test('goes back through several cards in order', () async {
      await facts.replaceFacts([fact(0), fact(1), fact(2)]);
      await service.completeCard('fact-0', liked: false);
      await service.completeCard('fact-1', liked: false);

      final first = await service.undo();
      expect(first.remaining.first.id, 'fact-1');

      final second = await service.undo();
      expect(second.remaining.first.id, 'fact-0');
      expect(second.canUndo, isFalse);
    });

    test('does nothing without a finished card', () async {
      await facts.replaceFacts([fact(0)]);

      final session = await service.undo();

      expect(session.completedCount, 0);
    });
  });

  group('the next day', () {
    test('a new deck skips what was read and resets progress', () async {
      await facts.replaceFacts([for (var i = 0; i < 25; i++) fact(i)]);
      final today = await service.loadToday();
      for (final fact in today.facts) {
        await service.completeCard(fact.id, liked: false);
      }

      now = now.add(const Duration(days: 1));
      final tomorrow = await service.loadToday();

      expect(tomorrow.completedCount, 0);
      expect(tomorrow.canUndo, isFalse);
      expect(tomorrow.facts.first.id, 'fact-10');
    });

    test('unfinished unread cards come back', () async {
      await facts.replaceFacts([for (var i = 0; i < 25; i++) fact(i)]);
      await service.completeCard('fact-0', liked: false);

      now = now.add(const Duration(days: 1));
      final tomorrow = await service.loadToday();

      expect(tomorrow.facts.first.id, 'fact-1');
    });
  });

  test('the countdown ends at the next local midnight', () async {
    await facts.replaceFacts([fact(0)]);
    now = DateTime(2026, 12, 31, 22, 30);

    final session = await service.loadToday();

    expect(session.deck.expiresAt, DateTime(2027));
    expect(
      service.timeUntilNextDeck(session),
      const Duration(hours: 1, minutes: 30),
    );
  });
}
