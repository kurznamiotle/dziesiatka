import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:dziesiatka/models/usage_row.dart';
import 'package:dziesiatka/services/admin_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AdminStatsService();
  final today = DateTime.utc(2026, 11, 20);

  UsageRow row(
    String installId,
    int daysAgo, {
    bool deckFinished = false,
    int cards = 0,
    int? quizCorrect,
    int? quizTotal,
    String? instructions,
    bool? choseAll,
    bool? notifications,
    int bonus = 0,
  }) {
    return UsageRow(
      day: today.subtract(Duration(days: daysAgo)),
      installId: installId,
      deckFinished: deckFinished,
      cardsCompleted: cards,
      quizCorrect: quizCorrect,
      quizTotal: quizTotal,
      instructions: instructions,
      choseAllCategories: choseAll,
      notificationsAllowed: notifications,
      bonusRounds: bonus,
    );
  }

  AdminFact fact(
    String id, {
    String category = 'Kosmos',
    String status = AdminFact.published,
  }) {
    return AdminFact(
      id: id,
      title: id,
      category: category,
      shortText: 'Krótki',
      longText: 'Długi',
      sourceLabel: 'NASA',
      status: status,
      quiz: const QuizQuestion(
        question: 'Pytanie?',
        options: ['A', 'B', 'C'],
        correctIndex: 0,
      ),
    );
  }

  group('usage', () {
    test('days are counted newest first', () {
      final summary = service.summarize([
        row('a', 1, deckFinished: true, cards: 10),
        row('b', 1, cards: 4),
        row('a', 0, cards: 2),
      ], today: today);

      expect(summary.installs, 2);
      expect(summary.days.first.activeUsers, 1);
      expect(summary.days.last.activeUsers, 2);
      expect(summary.days.last.finishedDeck, 1);
      expect(summary.days.last.averageCards, 7);
    });

    test('returns count only installs old enough to return', () {
      final summary = service.summarize([
        row('a', 10),
        row('a', 9),
        row('b', 10),
        row('c', 0),
      ], today: today);

      expect(summary.returnedAfterDay, 50);
      expect(summary.returnedAfterWeek, 0);
    });

    test('with too little data the percentages stay empty', () {
      final summary = service.summarize([row('a', 0)], today: today);

      expect(summary.returnedAfterDay, isNull);
      expect(summary.quizCorrectPercent, isNull);
    });

    test('the quiz percent adds up all answers', () {
      final summary = service.summarize([
        row('a', 1, quizCorrect: 4, quizTotal: 4),
        row('b', 1, quizCorrect: 0, quizTotal: 4),
      ], today: today);

      expect(summary.quizCorrectPercent, 50);
    });

    test('the first run is counted', () {
      final summary = service.summarize([
        row(
          'a',
          2,
          instructions: 'finished',
          choseAll: false,
          notifications: true,
          deckFinished: true,
        ),
        row(
          'b',
          1,
          instructions: 'skipped',
          choseAll: true,
          notifications: false,
        ),
        row('b', 0, deckFinished: true),
      ], today: today);

      expect(summary.finishedInstructions, 1);
      expect(summary.skippedInstructions, 1);
      expect(summary.choseFavorites, 1);
      expect(summary.choseAllCategories, 1);
      expect(summary.allowedNotifications, 1);
      expect(summary.deniedNotifications, 1);
      expect(summary.finishedFirstDeck, 1);
    });
  });

  group('facts', () {
    test('the ranking skips facts shown too rarely', () {
      final ranked = service.rankFacts(
        [fact('a'), fact('b'), fact('c')],
        {
          'a': const FactUsage(shown: 10, liked: 2),
          'b': const FactUsage(shown: 10, liked: 8),
          'c': const FactUsage(shown: 4, liked: 4),
        },
      );

      expect(ranked.map((item) => item.fact.id), ['b', 'a']);
    });

    test('questions too hard or too easy are suspicious', () {
      final suspicious = service.suspiciousQuestions(
        [fact('hard'), fact('easy'), fact('fine'), fact('rare')],
        {
          'hard': const FactUsage(quizCorrect: 1, quizWrong: 9),
          'easy': const FactUsage(quizCorrect: 10),
          'fine': const FactUsage(quizCorrect: 6, quizWrong: 4),
          'rare': const FactUsage(quizCorrect: 1, quizWrong: 1),
        },
      );

      expect(suspicious.map((item) => item.fact.id), ['hard', 'easy']);
    });
  });

  group('categories', () {
    test('stock counts only published facts, smallest first', () {
      final result = service.categories(
        [
          ...List.generate(9, (i) => fact('a$i')),
          fact('b', category: 'Historia'),
          fact('c', category: 'Historia', status: AdminFact.draft),
          fact('d', category: 'Historia', status: AdminFact.withdrawn),
        ],
        const {},
        {'Kosmos', 'Historia'},
      );

      expect(result.first.category, 'Historia');
      expect(result.first.published, 1);
      expect(result.first.drafts, 1);
      expect(result.last.daysLeft, 2);
    });

    test('results of a category add up', () {
      final result = service.categories(
        [fact('a'), fact('b')],
        {
          'a': const FactUsage(shown: 6, liked: 3, opened: 3),
          'b': const FactUsage(shown: 4, liked: 1),
        },
        {'Kosmos'},
      );

      expect(result.single.shown, 10);
      expect(result.single.likedPercent, 40);
      expect(result.single.openedPercent, 30);
    });

    test('a category without readers has no percent', () {
      final result = service.categories([], const {}, {'Kosmos'});

      expect(result.single.likedPercent, isNull);
    });
  });
}
