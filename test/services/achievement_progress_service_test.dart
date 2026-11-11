import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:dziesiatka/services/achievement_progress_service.dart';
import 'package:dziesiatka/services/achievements_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stored_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 12, 12);
  late AchievementProgressService service;

  Fact fact(
    int number, {
    String category = 'Kosmos',
    bool isRead = true,
    bool isFavorite = false,
    bool isWithdrawn = false,
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
      isWithdrawn: isWithdrawn,
      quiz: const QuizQuestion(
        question: 'Pytanie',
        options: ['A', 'B', 'C'],
        correctIndex: 0,
      ),
      createdAt: DateTime.utc(2026),
    );
  }

  void givenStorage(List<Fact> facts, [Map<String, Object> extra = const {}]) {
    SharedPreferences.setMockInitialValues({...storedFacts(facts), ...extra});
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = AchievementProgressService.local(
      factsService: FactsService(),
      now: () => now,
    );
  });

  test('gathers the progress from facts, answers, days and counts', () async {
    givenStorage(
      [
        fact(1, isFavorite: true),
        fact(2, category: 'Historia'),
        fact(3, isRead: false, category: 'Zwierzęta'),
      ],
      {
        'streakCount': 3,
        'streakLastCompleted': '2026-11-12',
        'shareCount': 2,
        'reviewCount': 4,
        'perfectReviewCount': 1,
        'perfectQuizCount': 7,
      },
    );
    await QuizHistoryService(
      now: () => now,
    ).recordAnswer('fact-1', isCorrect: true);

    final progress = await service.load();

    expect(progress.streak, 3);
    expect(progress.daysTotal, 3);
    expect(progress.factsRead, 2);
    expect(progress.favorites, 1);
    expect(progress.categoriesRead, 2);
    expect(progress.categoriesTotal, 3);
    expect(progress.remembered, 1);
    expect(progress.perfectQuizzes, 7);
    expect(progress.reviews, 4);
    expect(progress.perfectReviews, 1);
    expect(progress.shares, 2);
  });

  test('a user with 300 read facts gets read-250 at the first check', () async {
    givenStorage([for (var i = 0; i < 300; i++) fact(i)]);

    final first = await service.unlockNew();

    expect(first.map((item) => item.id), containsAll(['read-100', 'read-250']));
    expect(first.map((item) => item.id), isNot(contains('read-500')));
    expect(await service.unlockNew(), isEmpty);
  });

  group('categories-all', () {
    const categories = ['Kosmos', 'Historia', 'Zwierzęta', 'Psychologia'];

    Future<bool> unlocksCategories() async {
      final unlocked = await service.unlockNew();
      return unlocked.any((item) => item.id == 'categories-all');
    }

    test('stays locked while one category is missing', () async {
      givenStorage([
        for (final (index, category) in categories.indexed)
          fact(index, category: category, isRead: index != 3),
      ]);

      expect(await unlocksCategories(), isFalse);
    });

    test('unlocks once every category has a read fact', () async {
      givenStorage([
        for (final (index, category) in categories.indexed)
          fact(index, category: category),
      ]);

      expect(await unlocksCategories(), isTrue);
    });

    test('a withdrawn category is not required', () async {
      givenStorage([
        fact(0),
        fact(1, category: 'Historia', isRead: false, isWithdrawn: true),
      ]);

      expect(await unlocksCategories(), isTrue);
    });
  });

  test('shares count with anonymous statistics turned off', () async {
    givenStorage([fact(1)], {'usageStatsEnabled': false});
    await const AchievementsService().recordShare();

    final unlocked = await service.unlockNew();

    expect(unlocked.map((item) => item.id), contains('share-1'));
  });
}
