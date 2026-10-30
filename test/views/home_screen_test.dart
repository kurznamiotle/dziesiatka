import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/daily_review_screen.dart';
import 'package:dziesiatka/views/fact_card.dart';
import 'package:dziesiatka/views/share_card_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';

const _firstTitle = 'Dzień dłuższy niż rok';
const _secondTitle = 'Lodowe góry Plutona';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The cached asset future belongs to the previous test's fake async zone
    // and would never complete in this one.
    rootBundle.clear();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    DateTime Function()? now,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DziesiatkaApp(
        themeService: ThemeService(),
        now: now,
        random: const KeepOrderRandom(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Fact> storedFact(String title) async {
    final facts = await FactsService().getFacts();
    return facts.firstWhere((fact) => fact.title == title);
  }

  Future<int> favoriteCount() async {
    final facts = await FactsService().getFacts();
    return facts.where((fact) => fact.isFavorite).length;
  }

  Future<void> finishRemainingCards(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.tap(find.text('Dalej'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> answerQuiz(WidgetTester tester) async {
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.textContaining(RegExp(r'^A\. ')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }
  }

  Future<void> finishDay(WidgetTester tester) async {
    await finishRemainingCards(tester, 10);
    await answerQuiz(tester);
  }

  Finder undoButton() => find.byTooltip('Cofnij');

  IconButton undoIconButton(WidgetTester tester) {
    return tester.widget<IconButton>(
      find.ancestor(of: undoButton(), matching: find.byType(IconButton)),
    );
  }

  testWidgets('shows progress and the first card of the deck', (tester) async {
    await pumpApp(tester);

    expect(find.text('0 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsOneWidget);
    expect(find.text('Kosmos'), findsWidgets);
    expect(find.byTooltip('Ulubione'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('the left button moves on without liking', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsNothing);
    expect(find.text(_secondTitle), findsOneWidget);
    expect((await storedFact(_firstTitle)).isRead, isTrue);
    expect(await favoriteCount(), 0);
  });

  testWidgets('the right button likes the card and moves on', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Polub'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect((await storedFact(_firstTitle)).isFavorite, isTrue);
  });

  testWidgets('double tap completes only one card', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Dalej'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
  });

  testWidgets('swiping left moves on without liking', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.text(_firstTitle), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect((await storedFact(_firstTitle)).isRead, isTrue);
    expect(await favoriteCount(), 0);
  });

  testWidgets('swiping right likes the card', (tester) async {
    await pumpApp(tester);

    await tester.drag(find.text(_firstTitle), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect((await storedFact(_firstTitle)).isFavorite, isTrue);
  });

  testWidgets('only a drag to the right shows the like label', (tester) async {
    await pumpApp(tester);
    final center = tester.getCenter(find.text(_firstTitle));
    expect(find.text('Lubię to'), findsNothing);

    final right = await tester.startGesture(center);
    await right.moveBy(const Offset(40, 0));
    await tester.pump();
    await right.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(find.text('Lubię to'), findsOneWidget);

    // A far swipe must not carry the label off the screen.
    await right.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(tester.getTopRight(find.text('Lubię to')).dx, lessThan(390));

    await right.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(find.text('Lubię to'), findsNothing);

    await right.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a short slow drag returns the card to the deck', (tester) async {
    await pumpApp(tester);
    final restingPosition = tester.getCenter(find.text(_firstTitle));

    final gesture = await tester.startGesture(restingPosition);
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('0 / 10 ukończone'), findsOneWidget);
    expect(tester.getCenter(find.text(_firstTitle)), restingPosition);
    expect((await storedFact(_firstTitle)).isRead, isFalse);
    expect(await favoriteCount(), 0);
  });

  testWidgets('undo brings the card back and clears its like', (tester) async {
    await pumpApp(tester);
    expect(undoIconButton(tester).onPressed, isNull);

    await tester.tap(find.text('Polub'));
    await tester.pumpAndSettle();
    await tester.tap(undoButton());
    await tester.pumpAndSettle();

    expect(find.text('0 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsOneWidget);
    expect(await favoriteCount(), 0);
    expect((await storedFact(_firstTitle)).isRead, isFalse);
    expect(undoIconButton(tester).onPressed, isNull);
    expect(tester.getCenter(find.text(_firstTitle)).dx, closeTo(390 / 2, 100));
  });

  testWidgets('progress survives closing the app', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect(find.text(_secondTitle), findsOneWidget);
  });

  testWidgets('the card shows short text and expands to the details', (
    tester,
  ) async {
    await pumpApp(tester);
    final fact = await storedFact(_firstTitle);

    expect(find.text(fact.shortText), findsOneWidget);
    expect(find.text(fact.longText), findsNothing);

    await tester.tap(find.text('Dowiedz się więcej').last);
    await tester.pumpAndSettle();

    expect(find.text(fact.longText), findsOneWidget);
    expect(find.text(fact.sourceLabel), findsOneWidget);
    expect(find.text('0 / 10 ukończone'), findsOneWidget);
  });

  testWidgets('sources that are not links stay plain text', (tester) async {
    final facts = await FactsService().getFacts();
    await FactsService().setCardState(
      facts[0].id,
      isRead: true,
      isFavorite: false,
      lastReadAt: null,
    );
    await FactsService().setCardState(
      facts[1].id,
      isRead: true,
      isFavorite: false,
      lastReadAt: null,
    );
    await pumpApp(tester);

    await tester.tap(find.text('Dowiedz się więcej').last);
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.text(facts[2].sourceLabel),
        matching: find.byType(SelectableText),
      ),
      findsOneWidget,
    );
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

    const lightImpact = 'HapticFeedbackType.lightImpact';

    testWidgets('moving on, liking and undo give a light impact', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('Dalej'));
      await tester.pumpAndSettle();
      expect(vibrations, [lightImpact]);

      await tester.tap(find.text('Polub'));
      await tester.pumpAndSettle();
      expect(vibrations, [lightImpact, lightImpact]);

      await tester.tap(undoButton());
      await tester.pumpAndSettle();
      expect(vibrations, [lightImpact, lightImpact, lightImpact]);
    });

    testWidgets('swiping in both directions gives a light impact', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.drag(find.text(_firstTitle), const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.text(_secondTitle), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(vibrations, [lightImpact, lightImpact]);
    });

    testWidgets('a drag that returns gives no impact', (tester) async {
      await pumpApp(tester);
      final center = tester.getCenter(find.text(_firstTitle));

      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(vibrations, isEmpty);
    });
  });

  group('deck rendering', () {
    testWidgets('draws at most 3 cards', (tester) async {
      await pumpApp(tester);

      expect(find.byType(FactCard), findsNWidgets(3));
    });

    testWidgets('draws fewer cards when fewer remain', (tester) async {
      await pumpApp(tester);

      await finishRemainingCards(tester, 9);

      expect(find.byType(FactCard), findsOneWidget);
    });

    testWidgets('a drag does not rebuild any card', (tester) async {
      await pumpApp(tester);
      List<FactCard> cards() {
        return tester.widgetList<FactCard>(find.byType(FactCard)).toList();
      }

      final before = cards();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(_firstTitle)),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      final during = cards();
      await gesture.moveBy(const Offset(-100, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      for (var i = 0; i < before.length; i++) {
        expect(identical(before[i], during[i]), isTrue);
      }
    });

    testWidgets('every card repaints on its own', (tester) async {
      await pumpApp(tester);

      expect(
        find.ancestor(
          of: find.byType(FactCard),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
      for (final element in find.byType(FactCard).evaluate()) {
        final parent = element.findAncestorWidgetOfExactType<RepaintBoundary>();
        expect(parent, isNotNull);
      }
    });

    testWidgets('the cards below move up as the top one leaves', (
      tester,
    ) async {
      await pumpApp(tester);
      final second = find.text(_secondTitle);
      final resting = tester.getCenter(second);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text(_firstTitle)),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      expect(tester.getCenter(second).dy, lessThan(resting.dy));
      await gesture.moveBy(const Offset(-120, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('the card opens the share preview', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Udostępnij').last);
    await tester.pumpAndSettle();

    expect(find.byType(ShareCardSheet), findsOneWidget);
    expect(find.text('Udostępnij grafikę'), findsOneWidget);
    expect(find.text('0 / 10 ukończone'), findsOneWidget);
  });

  group('review cards', () {
    Future<void> givenFactReadDaysAgo(int days, DateTime now) async {
      final facts = await FactsService().getFacts();
      await FactsService().setCardState(
        facts.first.id,
        isRead: true,
        isFavorite: false,
        lastReadAt: now.subtract(Duration(days: days)),
      );
    }

    testWidgets('a due fact is the last card and shows the badge', (
      tester,
    ) async {
      final now = DateTime(2026, 11, 5, 12);
      await givenFactReadDaysAgo(3, now);
      await pumpApp(tester, now: () => now);

      expect(find.text('Powtórka'), findsNothing);
      expect(find.text('0 / 10 ukończone'), findsOneWidget);

      await finishRemainingCards(tester, 9);

      expect(find.text(_firstTitle), findsOneWidget);
      expect(find.text('Powtórka'), findsOneWidget);
    });

    testWidgets('a fact that is not due stays out of the deck', (tester) async {
      final now = DateTime(2026, 11, 5, 12);
      await givenFactReadDaysAgo(2, now);
      await pumpApp(tester, now: () => now);

      await finishRemainingCards(tester, 9);

      expect(find.text(_firstTitle), findsNothing);
      expect(find.text('Powtórka'), findsNothing);
    });

    testWidgets('today\'s review screen marks the review too', (tester) async {
      final now = DateTime(2026, 11, 5, 12);
      await givenFactReadDaysAgo(3, now);
      await pumpApp(tester, now: () => now);
      await finishRemainingCards(tester, 10);
      await answerQuiz(tester);

      await tester.tap(find.text('Powtórz dzisiejszą talię'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 9; i++) {
        await tester.tap(find.text('Następna'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Powtórka'), findsOneWidget);
    });
  });

  group('after finishing the deck', () {
    testWidgets('the quiz appears before the summary', (tester) async {
      await pumpApp(tester);

      await finishRemainingCards(tester, 10);

      expect(find.text('Pytanie 1 / 2'), findsOneWidget);
      expect(find.text('Gratulacje!'), findsNothing);
      expect(find.text('Dalej'), findsNothing);
    });

    testWidgets('undo from the quiz returns to the last card', (tester) async {
      await pumpApp(tester);
      await finishRemainingCards(tester, 10);

      await tester.tap(find.text('Cofnij ostatnią kartę'));
      await tester.pumpAndSettle();

      expect(find.text('9 / 10 ukończone'), findsOneWidget);
      expect(find.text('Plecione oprogramowanie Apollo'), findsOneWidget);
    });

    testWidgets('the summary shows the score, streak and countdown', (
      tester,
    ) async {
      await pumpApp(tester, now: () => DateTime(2026, 11, 2, 21, 30, 15));

      await finishDay(tester);

      expect(find.text('Gratulacje!'), findsOneWidget);
      expect(find.text('10 / 10 ukończone'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d/2 poprawne!$')), findsOneWidget);
      expect(find.text('Seria: 1 dzień'), findsOneWidget);
      expect(find.text('Następna dziesiątka za: 02:29:45'), findsOneWidget);
    });

    testWidgets('the summary is still there after a restart', (tester) async {
      await pumpApp(tester);
      await finishDay(tester);

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester);

      expect(find.text('Gratulacje!'), findsOneWidget);
      expect(find.textContaining('Pytanie'), findsNothing);
    });

    testWidgets('an unanswered quiz comes back after a restart', (
      tester,
    ) async {
      await pumpApp(tester);
      await finishRemainingCards(tester, 10);

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester);

      expect(find.text('Pytanie 1 / 2'), findsOneWidget);
    });

    testWidgets('the countdown ticks every second', (tester) async {
      var now = DateTime(2026, 11, 2, 21, 30, 15);
      await pumpApp(tester, now: () => now);
      await finishDay(tester);

      now = now.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Następna dziesiątka za: 02:29:40'), findsOneWidget);
    });

    testWidgets('a new deck appears at midnight', (tester) async {
      var now = DateTime(2026, 11, 2, 23, 59, 50);
      await pumpApp(tester, now: () => now);
      await finishDay(tester);

      now = DateTime(2026, 11, 3, 0, 0, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Gratulacje!'), findsNothing);
      expect(find.text('0 / 10 ukończone'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('finishing the next day grows the streak', (tester) async {
      var now = DateTime(2026, 11, 2, 12);
      await pumpApp(tester, now: () => now);
      await finishDay(tester);

      await tester.pumpWidget(const SizedBox());
      now = DateTime(2026, 11, 3, 12);
      await pumpApp(tester, now: () => now);
      await finishDay(tester);

      expect(find.text('Seria: 2 dni'), findsOneWidget);
    });

    testWidgets('review shows today\'s cards and changes nothing', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Polub'));
      await tester.pumpAndSettle();
      await finishRemainingCards(tester, 9);
      await answerQuiz(tester);
      String snapshot(Fact fact) {
        return '${fact.toJson()} ${fact.state.toJson()}';
      }

      final before = (await FactsService().getFacts()).map(snapshot).toList();

      await tester.tap(find.text('Powtórz dzisiejszą talię'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyReviewScreen), findsOneWidget);
      expect(find.text('Powtórka 1 / 10'), findsOneWidget);
      expect(find.text(_firstTitle), findsOneWidget);

      await tester.tap(find.text('Następna'));
      await tester.pumpAndSettle();
      expect(find.text('Powtórka 2 / 10'), findsOneWidget);
      expect(find.text(_secondTitle), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Gratulacje!'), findsOneWidget);
      final after = (await FactsService().getFacts()).map(snapshot).toList();
      expect(after, before);
    });
  });

  group('favorites', () {
    testWidgets('lists liked facts, opens details and removes them', (
      tester,
    ) async {
      await pumpApp(tester);
      final fact = await storedFact(_firstTitle);
      await tester.tap(find.text('Polub'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ulubione'));
      await tester.pumpAndSettle();
      expect(find.text(_firstTitle), findsOneWidget);

      await tester.tap(find.text(_firstTitle));
      await tester.pumpAndSettle();
      expect(find.text(fact.longText), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Usuń z ulubionych'));
      await tester.pumpAndSettle();

      expect(find.text(_firstTitle), findsNothing);
      expect(find.textContaining('Nie masz jeszcze'), findsOneWidget);
      expect(await favoriteCount(), 0);
    });

    testWidgets('returning from favorites keeps deck progress', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Polub'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ulubione'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('1 / 10 ukończone'), findsOneWidget);
      expect(find.text(_secondTitle), findsOneWidget);
    });
  });
}
