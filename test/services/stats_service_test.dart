import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_record.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:dziesiatka/services/stats_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stored_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final answeredAt = DateTime(2026, 11, 1);
  late DateTime now;
  late StatsService service;

  Fact fact(
    int number, {
    String category = 'Kosmos',
    bool isRead = false,
    bool isFavorite = false,
  }) {
    return Fact(
      id: 'fact-$number',
      title: 'Fakt $number',
      category: category,
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      sourceLabel: 'Źródło',
      isRead: isRead,
      isFavorite: isFavorite,
      createdAt: DateTime.utc(2026),
    );
  }

  QuizRecord record({
    required int answered,
    required int correct,
    required bool wasLastCorrect,
  }) {
    return QuizRecord(
      answered: answered,
      correct: correct,
      wasLastCorrect: wasLastCorrect,
      lastAnsweredAt: answeredAt,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 2, 12);
    service = StatsService(
      FactsService(),
      StreakService(now: () => now),
      QuizHistoryService(now: () => now),
    );
  });

  group('summarize', () {
    test('counts read facts and distinct finished days', () {
      final stats = service.summarize(
        facts: [fact(1, isRead: true), fact(2, isRead: true), fact(3)],
        records: const {},
        completedDays: ['2026-10-01', '2026-10-05', '2026-10-05'],
      );

      expect(stats.factsRead, 2);
      expect(stats.daysCompleted, 2);
    });

    test('remembers facts whose last answer was right', () {
      final stats = service.summarize(
        facts: [fact(1), fact(2), fact(3)],
        records: {
          'fact-1': record(answered: 2, correct: 1, wasLastCorrect: true),
          'fact-2': record(answered: 2, correct: 2, wasLastCorrect: true),
          'fact-3': record(answered: 5, correct: 4, wasLastCorrect: false),
        },
        completedDays: const [],
      );

      expect(stats.factsRemembered, 2);
      expect(stats.answersGiven, 9);
      expect(stats.answersCorrect, 7);
      expect(stats.accuracyPercent, 78);
    });

    test('leaves out records of facts that are gone', () {
      final stats = service.summarize(
        facts: [fact(1)],
        records: {
          'fact-1': record(answered: 1, correct: 1, wasLastCorrect: true),
          'gone': record(answered: 3, correct: 0, wasLastCorrect: false),
        },
        completedDays: const [],
      );

      expect(stats.factsRemembered, 1);
      expect(stats.accuracyPercent, 100);
    });

    test('has no accuracy before the first answer', () {
      final stats = service.summarize(
        facts: [fact(1)],
        records: const {},
        completedDays: const [],
      );

      expect(stats.accuracyPercent, isNull);
      expect(stats.factsRemembered, 0);
    });

    test('the favorite category has the most likes', () {
      final stats = service.summarize(
        facts: [
          fact(1, category: 'Historia', isFavorite: true),
          fact(2, category: 'Zwierzęta', isFavorite: true),
          fact(3, category: 'Zwierzęta', isFavorite: true),
          fact(4, category: 'Historia'),
          fact(5, category: 'Historia'),
        ],
        records: const {},
        completedDays: const [],
      );

      expect(stats.favoriteCategory, 'Zwierzęta');
    });

    test('a tie goes to the first category alphabetically', () {
      final stats = service.summarize(
        facts: [
          fact(1, category: 'Zwierzęta', isFavorite: true),
          fact(2, category: 'Historia', isFavorite: true),
        ],
        records: const {},
        completedDays: const [],
      );

      expect(stats.favoriteCategory, 'Historia');
    });

    test('there is no favorite category without likes', () {
      final stats = service.summarize(
        facts: [fact(1, isRead: true)],
        records: const {},
        completedDays: const [],
      );

      expect(stats.favoriteCategory, isNull);
    });
  });

  test('load reads facts, answers and days from the device', () async {
    SharedPreferences.setMockInitialValues({
      ...storedFacts([
        fact(1, isRead: true, isFavorite: true, category: 'Nauka'),
        fact(2, isRead: true),
      ]),
      'streakCount': 2,
      'streakLastCompleted': '2026-11-01',
    });
    await QuizHistoryService(
      now: () => now,
    ).recordAnswer('fact-1', isCorrect: true);
    await QuizHistoryService(
      now: () => now,
    ).recordAnswer('fact-2', isCorrect: false);

    final stats = await service.load();

    expect(stats.daysCompleted, 2);
    expect(stats.factsRead, 2);
    expect(stats.factsRemembered, 1);
    expect(stats.accuracyPercent, 50);
    expect(stats.favoriteCategory, 'Nauka');
  });
}
