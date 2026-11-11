import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/daily_quiz_screen.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _feedback = Duration(seconds: 1);

const _questions = [
  QuizQuestion(
    question: 'Pierwsze pytanie',
    options: ['Dobra', 'Zła', 'Inna'],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Drugie pytanie',
    options: ['Jeden', 'Dwa', 'Trzy'],
    correctIndex: 2,
  ),
];

void main() {
  late List<int> results;
  late int undoCount;

  Future<void> pumpQuiz(WidgetTester tester, {List<Fact>? facts}) async {
    results = [];
    undoCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DailyQuizScreen(
            questions: _questions,
            facts: facts,
            onFinished: results.add,
            onUndo: () => undoCount++,
          ),
        ),
      ),
    );
  }

  Color optionColor(WidgetTester tester, String label) {
    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );
    return material.color!;
  }

  testWidgets('shows the question with lettered options', (tester) async {
    await pumpQuiz(tester);

    expect(find.text('Pytanie 1 / 2'), findsOneWidget);
    expect(find.text('Pierwsze pytanie'), findsOneWidget);
    expect(find.text('A. Dobra'), findsOneWidget);
    expect(find.text('B. Zła'), findsOneWidget);
    expect(find.text('C. Inna'), findsOneWidget);
  });

  group('haptics', () {
    late List<String> vibrations;

    setUp(() {
      vibrations = [];
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              vibrations.add(call.arguments as String);
            }
            return null;
          });
    });

    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('a correct answer gives a medium impact', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.text('A. Dobra'));
      await tester.pump(_feedback);

      expect(vibrations, ['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('a wrong answer gives a heavy impact', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.text('B. Zła'));
      await tester.pump(_feedback);

      expect(vibrations, ['HapticFeedbackType.heavyImpact']);
    });

    testWidgets('a second tap gives no extra impact', (tester) async {
      await pumpQuiz(tester);

      await tester.tap(find.text('B. Zła'));
      await tester.pump();
      await tester.tap(find.text('A. Dobra'));
      await tester.pump(_feedback);

      expect(vibrations, hasLength(1));
    });
  });

  testWidgets('a correct answer turns green', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('A. Dobra'));
    await tester.pump();

    expect(optionColor(tester, 'A. Dobra'), const Color(0xFF15803D));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.pump(_feedback);
  });

  testWidgets('a wrong answer turns red and reveals the right one', (
    tester,
  ) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('B. Zła'));
    await tester.pump();

    expect(optionColor(tester, 'B. Zła'), const Color(0xFFB91C1C));
    expect(optionColor(tester, 'A. Dobra'), const Color(0xFF15803D));
    await tester.pump(_feedback);
  });

  testWidgets('moves on after the feedback and reports the score', (
    tester,
  ) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('A. Dobra'));
    await tester.pump(_feedback);
    await tester.pump();
    expect(find.text('Pytanie 2 / 2'), findsOneWidget);
    expect(find.text('Drugie pytanie'), findsOneWidget);
    expect(results, isEmpty);

    await tester.tap(find.text('A. Jeden'));
    await tester.pump(_feedback);

    expect(results, [1]);
  });

  testWidgets('a second tap cannot change the answer', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('B. Zła'));
    await tester.pump();
    await tester.tap(find.text('A. Dobra'));
    await tester.pump(_feedback);
    await tester.pump();

    await tester.tap(find.text('C. Trzy'));
    await tester.pump(_feedback);

    expect(results, [1]);
  });

  testWidgets('there is no undo without a deck behind the quiz', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DailyQuizScreen(questions: _questions, onFinished: (_) {}),
        ),
      ),
    );

    expect(find.text('Cofnij ostatnią kartę'), findsNothing);
  });

  testWidgets('undo is offered only before the first answer', (tester) async {
    await pumpQuiz(tester);

    await tester.tap(find.text('Cofnij ostatnią kartę'));
    expect(undoCount, 1);

    await tester.tap(find.text('A. Dobra'));
    await tester.pump();

    expect(find.text('Cofnij ostatnią kartę').hitTestable(), findsNothing);
    await tester.pump(_feedback);
  });

  group('the hint', () {
    final facts = [
      for (final (index, question) in _questions.indexed)
        Fact(
          id: 'fact-$index',
          title: 'Ciekawostka ${index + 1}',
          category: 'Kosmos',
          shortText: 'Zajawka',
          longText: 'Całe rozwinięcie ${index + 1}',
          sourceLabel: 'Źródło',
          quiz: question,
          createdAt: DateTime.utc(2026),
        ),
    ];

    testWidgets('opens the fact behind the current question', (tester) async {
      await pumpQuiz(tester, facts: facts);
      await tester.tap(find.text('A. Dobra'));
      await tester.pump(_feedback);
      await tester.pump();

      await tester.tap(find.text('Przypomnij sobie'));
      await tester.pumpAndSettle();

      expect(find.byType(FactDetailsSheet), findsOneWidget);
      expect(find.text('Ciekawostka 2'), findsOneWidget);
      expect(find.text('Całe rozwinięcie 2'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Pytanie 2 / 2'), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('is gone once the question is answered', (tester) async {
      await pumpQuiz(tester, facts: facts);
      expect(find.text('Przypomnij sobie').hitTestable(), findsOneWidget);

      await tester.tap(find.text('B. Zła'));
      await tester.pump();

      expect(find.text('Przypomnij sobie').hitTestable(), findsNothing);
      await tester.pump(_feedback);
    });

    testWidgets('is not offered without the facts', (tester) async {
      await pumpQuiz(tester);

      expect(find.text('Przypomnij sobie'), findsNothing);
    });
  });
}
