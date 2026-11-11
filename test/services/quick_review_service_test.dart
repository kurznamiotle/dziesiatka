import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:dziesiatka/models/quiz_record.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/quick_review_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';
import '../helpers/stored_facts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 10, 12);
  late QuickReviewService service;

  Fact fact(
    int number, {
    DateTime? lastReadAt,
    bool isRead = true,
    bool hasQuiz = true,
    bool isWithdrawn = false,
  }) {
    return Fact(
      id: 'fact-$number',
      title: 'Fakt $number',
      category: 'Kosmos',
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      sourceLabel: 'Źródło',
      isRead: isRead,
      lastReadAt: lastReadAt,
      isWithdrawn: isWithdrawn,
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

  DateTime daysAgo(int days) => now.subtract(Duration(days: days));

  QuizRecord answered({required bool wasCorrect, required DateTime at}) {
    return QuizRecord(
      answered: 1,
      correct: wasCorrect ? 1 : 0,
      wasLastCorrect: wasCorrect,
      lastAnsweredAt: at,
    );
  }

  List<String> ids(List<Fact> facts) => facts.map((fact) => fact.id).toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = QuickReviewService(
      FactsService(),
      QuizHistoryService(now: () => now),
      now: () => now,
      random: const KeepOrderRandom(),
    );
  });

  test('asks only about facts read before today', () {
    final chosen = service.choose([
      fact(1, lastReadAt: daysAgo(1)),
      fact(2, lastReadAt: now.subtract(const Duration(hours: 2))),
      fact(3, isRead: false),
      fact(4, lastReadAt: daysAgo(2), hasQuiz: false),
      fact(5, lastReadAt: daysAgo(2), isWithdrawn: true),
    ], const {});

    expect(ids(chosen), ['fact-1']);
  });

  test('a fact read just before midnight counts as an earlier day', () {
    final chosen = service.choose([
      fact(1, lastReadAt: DateTime(2026, 11, 9, 23, 59)),
    ], const {});

    expect(ids(chosen), ['fact-1']);
  });

  test('a read fact without a date counts as read long ago', () {
    final chosen = service.choose([
      fact(1, lastReadAt: daysAgo(1)),
      fact(2),
    ], const {});

    expect(ids(chosen), ['fact-2', 'fact-1']);
  });

  test('is empty on the first day', () {
    final chosen = service.choose([
      fact(1, lastReadAt: now),
      fact(2, isRead: false),
    ], const {});

    expect(chosen, isEmpty);
  });

  test('takes at most 3 questions, the longest unseen first', () {
    final chosen = service.choose([
      for (var i = 1; i <= 6; i++) fact(i, lastReadAt: daysAgo(i)),
    ], const {});

    expect(ids(chosen), ['fact-6', 'fact-5', 'fact-4']);
  });

  test('a wrong last answer comes before everything else', () {
    final chosen = service.choose(
      [
        fact(1, lastReadAt: daysAgo(30)),
        fact(2, lastReadAt: daysAgo(2)),
        fact(3, lastReadAt: daysAgo(20)),
        fact(4, lastReadAt: daysAgo(10)),
      ],
      {'fact-2': answered(wasCorrect: false, at: daysAgo(2))},
    );

    expect(ids(chosen), ['fact-2', 'fact-1', 'fact-3']);
  });

  test('a recent answer counts as seeing the fact', () {
    final chosen = service.choose(
      [fact(1, lastReadAt: daysAgo(30)), fact(2, lastReadAt: daysAgo(5))],
      {'fact-1': answered(wasCorrect: true, at: daysAgo(1))},
    );

    expect(ids(chosen), ['fact-2', 'fact-1']);
  });

  test('chooseFacts reads facts and answers from the device', () async {
    SharedPreferences.setMockInitialValues(
      storedFacts([
        fact(1, lastReadAt: daysAgo(3)),
        fact(2, lastReadAt: daysAgo(1)),
      ]),
    );
    await service.recordAnswer('fact-2', isCorrect: false);

    expect(ids(await service.chooseFacts()), ['fact-2', 'fact-1']);
  });
}
