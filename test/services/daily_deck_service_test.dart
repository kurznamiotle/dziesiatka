import 'dart:convert';
import 'dart:math';

import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:dziesiatka/services/daily_deck_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FactsService facts;
  late DateTime now;
  late DailyDeckService service;

  DailyDeckService newService({Random random = const KeepOrderRandom()}) {
    return DailyDeckService(
      facts,
      StreakService(now: () => now),
      now: () => now,
      random: random,
    );
  }

  Fact fact(
    int number, {
    bool isRead = false,
    bool isFavorite = false,
    DateTime? lastReadAt,
    bool hasQuiz = true,
  }) {
    return Fact(
      id: 'fact-$number',
      title: 'Fakt $number',
      category: 'Kosmos',
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      source: 'Źródło',
      isRead: isRead,
      isFavorite: isFavorite,
      lastReadAt: lastReadAt,
      quiz: hasQuiz
          ? const QuizQuestion(
              question: 'Pytanie',
              options: ['A', 'B', 'C'],
              correctIndex: 0,
            )
          : null,
      createdAt: DateTime.utc(2026),
    );
  }

  DateTime daysAgo(int days, {int hours = 0}) {
    return now.subtract(Duration(days: days, hours: hours));
  }

  void givenPool(List<Fact> pool) {
    final encoded = jsonEncode(pool.map((fact) => fact.toJson()).toList());
    SharedPreferences.setMockInitialValues({'facts': encoded});
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

  group('random choice', () {
    Future<List<DailyDeck>> decksFromSeeds(int count) async {
      final decks = <DailyDeck>[];
      for (var seed = 0; seed < count; seed++) {
        await SharedPreferences.getInstance().then(
          (prefs) => prefs.remove('dailyDeck'),
        );
        final session = await newService(random: Random(seed)).loadToday();
        decks.add(session.deck);
      }
      return decks;
    }

    test('picks different new facts from the whole pool', () async {
      givenPool([for (var i = 0; i < 40; i++) fact(i)]);

      final decks = await decksFromSeeds(8);

      final firstTen = {for (var i = 0; i < 10; i++) 'fact-$i'};
      expect(decks.map((deck) => deck.factIds.toSet()).toSet().length, 8);
      expect(
        decks.expand((deck) => deck.factIds).toSet().difference(firstTen),
        isNotEmpty,
      );
      for (final deck in decks) {
        expect(deck.factIds, hasLength(10));
        expect(deck.factIds.toSet(), hasLength(10));
      }
    });

    test('asks about different positions of the deck', () async {
      givenPool([for (var i = 0; i < 40; i++) fact(i)]);

      final decks = await decksFromSeeds(8);

      final positions = {
        for (final deck in decks)
          for (final id in deck.quizFactIds) deck.factIds.indexOf(id),
      };
      expect(positions.length, greaterThan(2));
      for (final deck in decks) {
        expect(deck.quizFactIds, hasLength(2));
        expect(deck.quizFactIds.toSet(), hasLength(2));
        expect(deck.factIds, containsAll(deck.quizFactIds));
      }
    });

    test('still mixes 9 new facts with 1 due review', () async {
      givenPool([
        for (var i = 0; i < 40; i++)
          fact(i, isRead: i < 10, lastReadAt: i < 10 ? daysAgo(5) : null),
      ]);

      for (final deck in await decksFromSeeds(8)) {
        expect(deck.reviewFactIds, hasLength(1));
        expect(deck.factIds, hasLength(10));
      }
    });

    test('a restart during the day keeps the deck and questions', () async {
      givenPool([for (var i = 0; i < 40; i++) fact(i)]);

      final first = await newService(random: Random(1)).loadToday();
      now = now.add(const Duration(hours: 6));
      final second = await newService(random: Random(2)).loadToday();

      expect(second.deck.factIds, first.deck.factIds);
      expect(second.deck.quizFactIds, first.deck.quizFactIds);
    });

    test('the next day brings a new deck', () async {
      givenPool([for (var i = 0; i < 40; i++) fact(i)]);

      final first = await newService(random: Random(1)).loadToday();
      now = now.add(const Duration(days: 1));
      final second = await newService(random: Random(2)).loadToday();

      expect(second.deck.factIds, isNot(first.deck.factIds));
    });
  });

  group('choosing a deck', () {
    test('takes only new facts when nothing has been read', () async {
      givenPool([for (var i = 0; i < 30; i++) fact(i)]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(DailyDeckService.deckSize));
      expect(session.facts.first.id, 'fact-0');
      expect(session.facts.every((fact) => !fact.isRead), isTrue);
    });

    test('mixes 9 new facts with 1 due review', () async {
      givenPool([
        for (var i = 0; i < 30; i++)
          fact(i, isRead: i < 10, lastReadAt: i < 10 ? daysAgo(5) : null),
      ]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(10));
      expect(session.facts.where((fact) => !fact.isRead), hasLength(9));
      expect(session.facts.where((fact) => fact.isRead), hasLength(1));
    });

    test('a fact read 3 days ago is due', () async {
      givenPool([
        fact(0, isRead: true, lastReadAt: daysAgo(3)),
        for (var i = 1; i < 30; i++) fact(i),
      ]);

      final session = await service.loadToday();

      expect(session.deck.reviewFactIds, ['fact-0']);
    });

    test('a fact read 2 days ago is not due', () async {
      givenPool([
        fact(0, isRead: true, lastReadAt: daysAgo(2)),
        for (var i = 1; i < 30; i++) fact(i),
      ]);

      final session = await service.loadToday();

      expect(session.deck.reviewFactIds, isEmpty);
      expect(session.facts.map((fact) => fact.id), isNot(contains('fact-0')));
      expect(session.facts, hasLength(10));
    });

    test('the waiting time counts calendar days', () async {
      now = DateTime(2026, 11, 5, 0, 30);
      givenPool([
        fact(0, isRead: true, lastReadAt: DateTime(2026, 11, 2, 23, 30)),
        for (var i = 1; i < 30; i++) fact(i),
      ]);

      final session = await service.loadToday();

      expect(session.deck.reviewFactIds, ['fact-0']);
    });

    test('a read fact without a date is due', () async {
      givenPool([fact(0, isRead: true), for (var i = 1; i < 30; i++) fact(i)]);

      final session = await service.loadToday();

      expect(session.deck.reviewFactIds, ['fact-0']);
    });

    test('takes only one review when many are due', () async {
      givenPool([
        for (var i = 0; i < 30; i++)
          fact(i, isRead: i < 20, lastReadAt: i < 20 ? daysAgo(10) : null),
      ]);

      final session = await service.loadToday();

      expect(session.deck.reviewFactIds, hasLength(1));
    });

    test('draws reviews only from due facts on every day', () async {
      final drawn = <String>{};
      final random = Random(1);

      for (var day = 0; day < 8; day++) {
        now = DateTime(2026, 11, 2 + day, 12);
        givenPool([
          fact(0, isRead: true, lastReadAt: daysAgo(9)),
          fact(1, isRead: true, lastReadAt: daysAgo(4)),
          fact(2, isRead: true, lastReadAt: daysAgo(1)),
          fact(3, isRead: true, lastReadAt: daysAgo(2)),
          for (var i = 4; i < 40; i++) fact(i),
        ]);

        final session = await newService(random: random).loadToday();

        expect(session.deck.reviewFactIds, hasLength(1));
        drawn.addAll(session.deck.reviewFactIds);
      }

      expect(drawn, {'fact-0', 'fact-1'});
    });

    test('new facts fill the review slot when none is due', () async {
      givenPool([
        for (var i = 0; i < 30; i++)
          fact(i, isRead: i < 10, lastReadAt: i < 10 ? daysAgo(1) : null),
      ]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(10));
      expect(session.facts.every((fact) => !fact.isRead), isTrue);
    });

    test('the oldest read facts fill the deck when new ones run out', () async {
      givenPool([
        for (var i = 0; i < 4; i++) fact(i),
        fact(4, isRead: true, lastReadAt: daysAgo(1)),
        fact(5, isRead: true, lastReadAt: daysAgo(2)),
        fact(6, isRead: true, lastReadAt: daysAgo(1)),
        fact(7, isRead: true, lastReadAt: daysAgo(2)),
        fact(8, isRead: true, lastReadAt: daysAgo(1)),
        fact(9, isRead: true, lastReadAt: daysAgo(2)),
        fact(10, isRead: true, lastReadAt: daysAgo(1, hours: 3)),
        fact(11, isRead: true, lastReadAt: daysAgo(1)),
      ]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(10));
      expect(session.deck.reviewFactIds, hasLength(6));
      expect(
        session.facts.skip(4).take(3).map((fact) => fact.id),
        containsAll(['fact-5', 'fact-7', 'fact-9']),
      );
      expect(session.facts.skip(7).first.id, 'fact-10');
    });

    test('marks only already read facts as reviews', () async {
      givenPool([
        fact(0, isRead: true, lastReadAt: daysAgo(5)),
        for (var i = 1; i < 30; i++) fact(i),
      ]);

      final session = await service.loadToday();
      for (final card in session.remaining) {
        await service.completeCard(card.id, liked: false);
      }

      final finished = await service.loadToday();
      expect(finished.deck.reviewFactIds, ['fact-0']);
    });

    test('the review stays the same during the day', () async {
      givenPool([
        for (var i = 0; i < 30; i++)
          fact(i, isRead: i < 10, lastReadAt: i < 10 ? daysAgo(5) : null),
      ]);

      final first = await service.loadToday();
      now = now.add(const Duration(hours: 6));
      final second = await newService().loadToday();

      expect(second.deck.reviewFactIds, first.deck.reviewFactIds);
    });

    test('fills the deck with read facts when new ones run out', () async {
      givenPool([for (var i = 0; i < 12; i++) fact(i, isRead: i >= 3)]);

      final session = await service.loadToday();

      expect(session.facts, hasLength(10));
      expect(session.facts.take(3).every((fact) => !fact.isRead), isTrue);
      expect(session.facts.skip(3).every((fact) => fact.isRead), isTrue);
      expect(session.facts.map((fact) => fact.id).toSet(), hasLength(10));
    });

    test('uses the whole pool when it has fewer than 10 facts', () async {
      givenPool([for (var i = 0; i < 4; i++) fact(i)]);

      expect((await service.loadToday()).facts, hasLength(4));
    });

    test('reviews change from day to day', () async {
      givenPool([for (var i = 0; i < 20; i++) fact(i, isRead: true)]);

      final random = Random(1);
      final first = await newService(random: random).loadToday();
      now = now.add(const Duration(days: 1));
      final second = await newService(random: random).loadToday();

      expect(first.facts.first.id, isNot(second.facts.first.id));
    });
  });

  group('during the day', () {
    test('the same deck comes back after a restart', () async {
      givenPool([for (var i = 0; i < 20; i++) fact(i)]);
      final first = await service.loadToday();
      await service.completeCard('fact-0', liked: false);

      final second = await newService().loadToday();

      expect(
        second.facts.map((fact) => fact.id),
        first.facts.map((fact) => fact.id),
      );
    });

    test('completing a repeated fact counts toward today', () async {
      givenPool([for (var i = 0; i < 10; i++) fact(i, isRead: true)]);

      final session = await service.completeCard('fact-1', liked: false);

      expect(session.completedCount, 1);
      expect(session.remaining, hasLength(9));
    });

    test('a like sets the favorite flag and marks the fact read', () async {
      givenPool([fact(0)]);

      await service.completeCard('fact-0', liked: true);

      final saved = await stored('fact-0');
      expect(saved.isFavorite, isTrue);
      expect(saved.isRead, isTrue);
    });

    test('completing a card saves when it was read', () async {
      givenPool([fact(0)]);

      await service.completeCard('fact-0', liked: false);

      expect((await stored('fact-0')).lastReadAt, now);
    });

    test('a finished review waits 3 days again', () async {
      givenPool([
        fact(0, isRead: true, lastReadAt: daysAgo(5)),
        for (var i = 1; i < 30; i++) fact(i),
      ]);
      await service.completeCard('fact-0', liked: false);

      now = now.add(const Duration(days: 2));
      expect((await service.loadToday()).deck.reviewFactIds, isEmpty);

      now = now.add(const Duration(days: 1));
      expect((await service.loadToday()).deck.reviewFactIds, ['fact-0']);
    });

    test('moving on keeps an existing favorite', () async {
      givenPool([fact(0, isFavorite: true)]);

      await service.completeCard('fact-0', liked: false);

      expect((await stored('fact-0')).isFavorite, isTrue);
    });

    test('a card outside the remaining ones is ignored', () async {
      givenPool([fact(0), fact(1)]);
      await service.completeCard('fact-0', liked: false);

      final session = await service.completeCard('fact-0', liked: true);

      expect(session.completedCount, 1);
      expect((await stored('fact-0')).isFavorite, isFalse);
    });
  });

  group('undo', () {
    test('restores a card and its earlier state', () async {
      givenPool([fact(0), fact(1)]);
      await service.completeCard('fact-0', liked: true);

      final session = await service.undo();

      expect(session.remaining.first.id, 'fact-0');
      final saved = await stored('fact-0');
      expect(saved.isFavorite, isFalse);
      expect(saved.isRead, isFalse);
      expect(saved.lastReadAt, isNull);
    });

    test('keeps the state from before the swipe', () async {
      final readBefore = daysAgo(4);
      givenPool([
        fact(0, isRead: true, isFavorite: true, lastReadAt: readBefore),
      ]);
      await service.completeCard('fact-0', liked: true);

      await service.undo();

      final saved = await stored('fact-0');
      expect(saved.isRead, isTrue);
      expect(saved.isFavorite, isTrue);
      expect(saved.lastReadAt, readBefore);
    });

    test('still shows the review label after undo', () async {
      givenPool([
        fact(0, isRead: true, lastReadAt: daysAgo(5)),
        for (var i = 1; i < 30; i++) fact(i),
      ]);
      final session = await service.loadToday();
      for (final card in session.remaining) {
        await service.completeCard(card.id, liked: false);
      }

      final restored = await service.undo();

      expect(restored.remaining.single.id, 'fact-0');
      expect(restored.deck.reviewFactIds, ['fact-0']);
    });

    test('goes back through several cards in order', () async {
      givenPool([fact(0), fact(1), fact(2)]);
      await service.completeCard('fact-0', liked: false);
      await service.completeCard('fact-1', liked: false);

      final first = await service.undo();
      expect(first.remaining.first.id, 'fact-1');

      final second = await service.undo();
      expect(second.remaining.first.id, 'fact-0');
      expect(second.canUndo, isFalse);
    });

    test('does nothing without a finished card', () async {
      givenPool([fact(0)]);

      final session = await service.undo();

      expect(session.completedCount, 0);
    });
  });

  group('quiz', () {
    Future<void> finishCards(DailyDeckService service) async {
      final session = await service.loadToday();
      for (final card in session.remaining) {
        await service.completeCard(card.id, liked: false);
      }
    }

    test('offers 2 questions from today\'s deck', () async {
      givenPool([for (var i = 0; i < 30; i++) fact(i)]);

      final session = await service.loadToday();

      expect(session.quizQuestions, hasLength(2));
      expect(
        session.facts.map((fact) => fact.id),
        containsAll(session.deck.quizFactIds),
      );
    });

    test('skips facts without a question', () async {
      givenPool([for (var i = 0; i < 10; i++) fact(i, hasQuiz: i == 7)]);

      final session = await service.loadToday();

      expect(session.deck.quizFactIds, ['fact-7']);
    });

    test('is pending only after the last card', () async {
      givenPool([for (var i = 0; i < 3; i++) fact(i)]);

      expect((await service.loadToday()).isQuizPending, isFalse);

      await finishCards(service);

      expect((await service.loadToday()).isQuizPending, isTrue);
    });

    test('finishing saves the score and counts the streak', () async {
      givenPool([fact(0), fact(1)]);
      await finishCards(service);
      expect((await service.loadToday()).streak, 0);

      final session = await service.finishQuiz(1);

      expect(session.isQuizPending, isFalse);
      expect(session.deck.quizCorrect, 1);
      expect(session.streak, 1);
    });

    test('a finished quiz stays finished after a restart', () async {
      givenPool([fact(0), fact(1)]);
      await finishCards(service);
      await service.finishQuiz(2);

      final session = await newService().loadToday();

      expect(session.isQuizPending, isFalse);
      expect(session.deck.quizCorrect, 2);
    });

    test('an unfinished quiz comes back after a restart', () async {
      givenPool([fact(0), fact(1)]);
      await finishCards(service);

      expect((await newService().loadToday()).isQuizPending, isTrue);
    });

    test('finishing is ignored before the cards are done', () async {
      givenPool([fact(0), fact(1)]);

      final session = await service.finishQuiz(2);

      expect(session.deck.quizCorrect, isNull);
      expect(session.streak, 0);
    });

    test('a deck without questions counts the streak at once', () async {
      givenPool([fact(0, hasQuiz: false)]);

      final session = await service.completeCard('fact-0', liked: false);

      expect(session.isQuizPending, isFalse);
      expect(session.streak, 1);
    });

    test('the streak grows across days', () async {
      givenPool([for (var i = 0; i < 40; i++) fact(i)]);
      await finishCards(service);
      await service.finishQuiz(2);

      now = now.add(const Duration(days: 1));
      await finishCards(service);
      final session = await service.finishQuiz(1);

      expect(session.streak, 2);
    });
  });

  group('the next day', () {
    test('a new deck moves on to new facts and resets progress', () async {
      givenPool([for (var i = 0; i < 25; i++) fact(i)]);
      final today = await service.loadToday();
      for (final card in today.facts) {
        await service.completeCard(card.id, liked: false);
      }

      now = now.add(const Duration(days: 1));
      final tomorrow = await service.loadToday();

      expect(tomorrow.completedCount, 0);
      expect(tomorrow.canUndo, isFalse);
      expect(tomorrow.facts.first.id, 'fact-10');
      expect(tomorrow.facts.where((fact) => fact.isRead), isEmpty);
    });

    test('unfinished unread cards come back', () async {
      givenPool([for (var i = 0; i < 25; i++) fact(i)]);
      await service.completeCard('fact-0', liked: false);

      now = now.add(const Duration(days: 1));
      final tomorrow = await service.loadToday();

      expect(tomorrow.facts.first.id, 'fact-1');
    });
  });

  test('the countdown ends at the next local midnight', () async {
    givenPool([fact(0)]);
    now = DateTime(2026, 12, 31, 22, 30);

    final session = await service.loadToday();

    expect(session.deck.expiresAt, DateTime(2027));
    expect(
      service.timeUntilNextDeck(session),
      const Duration(hours: 1, minutes: 30),
    );
  });
}
