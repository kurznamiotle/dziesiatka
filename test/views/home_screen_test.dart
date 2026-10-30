import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DziesiatkaApp(themeService: ThemeService()));
    await tester.pumpAndSettle();
  }

  Future<int> readCount() async {
    final facts = await FactsService().getFacts();
    return facts.where((fact) => fact.isRead).length;
  }

  testWidgets('shows progress and the first unread card', (tester) async {
    await pumpApp(tester);

    expect(find.text('0 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsOneWidget);
    expect(find.text('Kosmos'), findsWidgets);
  });

  testWidgets('action buttons mark the card as read', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Następna'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsNothing);
    expect(find.text(_secondTitle), findsOneWidget);

    await tester.tap(find.text('Odrzuć'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 10 ukończone'), findsOneWidget);
    expect(await readCount(), 2);
  });

  testWidgets('double tap dismisses only one card', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Następna'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Następna'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
  });

  testWidgets('swiping past the threshold marks the card as read', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.drag(find.text(_firstTitle), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('1 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsNothing);
    expect(await readCount(), 1);
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
    expect(await readCount(), 0);
  });

  testWidgets('finishing the deck shows completion and reset restores it', (
    tester,
  ) async {
    await pumpApp(tester);

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('Następna'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Gratulacje!'), findsOneWidget);
    expect(find.text('10 / 10 ukończone'), findsOneWidget);
    expect(find.text('Następna'), findsNothing);

    await tester.tap(find.text('Zresetuj postęp'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 10 ukończone'), findsOneWidget);
    expect(find.text(_firstTitle), findsOneWidget);
    expect(await readCount(), 0);
  });

  testWidgets('the card shows short text and expands to the details', (
    tester,
  ) async {
    await pumpApp(tester);
    final fact = (await FactsService().getFacts()).first;

    expect(find.text(fact.shortText), findsOneWidget);
    expect(find.text(fact.longText), findsNothing);

    await tester.tap(find.text('Dowiedz się więcej').last);
    await tester.pumpAndSettle();

    expect(find.text(fact.longText), findsOneWidget);
    expect(find.text(fact.source), findsOneWidget);
    expect(find.text('0 / 10 ukończone'), findsOneWidget);
  });

  testWidgets('sources that are not links stay plain text', (tester) async {
    await pumpApp(tester);
    final facts = await FactsService().getFacts();
    await FactsService().replaceFacts([facts[2]]);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    await tester.tap(find.text('Dowiedz się więcej').last);
    await tester.pumpAndSettle();

    expect(find.text(facts[2].source), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(facts[2].source),
        matching: find.byType(SelectableText),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a deleted fact leaves the deck after the admin panel closes', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Panel twórcy'));
    await tester.pumpAndSettle();
    expect(find.text('Panel twórcy'), findsOneWidget);

    await tester.tap(find.text('Fakty'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Usuń').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('0 / 9 ukończone'), findsOneWidget);
  });

  testWidgets('an empty database points to the admin panel', (tester) async {
    await pumpApp(tester);
    await FactsService().replaceFacts([]);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    expect(find.textContaining('Brak ciekawostek'), findsOneWidget);
    expect(find.text('Gratulacje!'), findsNothing);
  });

  testWidgets('wide layouts center a 440px phone frame', (tester) async {
    await pumpApp(tester, size: const Size(1200, 900));

    final headerLeft = tester.getTopLeft(find.text('Dziesiątka')).dx;
    expect(headerLeft, (1200 - 440) / 2 + 24);
  });

  testWidgets('narrow layouts use the full width', (tester) async {
    await pumpApp(tester);

    expect(tester.getTopLeft(find.text('Dziesiątka')).dx, 24);
  });
}
