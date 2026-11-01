import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/category_preferences_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/favorite_categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stored_facts.dart';

void main() {
  var finished = 0;

  Fact fact(String id, String category) {
    return Fact(
      id: id,
      title: id,
      category: category,
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      sourceLabel: 'Źródło',
      createdAt: DateTime.utc(2026),
    );
  }

  setUp(() {
    finished = 0;
    SharedPreferences.setMockInitialValues(
      storedFacts([
        fact('a', 'Kosmos'),
        fact('b', 'Historia'),
        fact('c', 'Psychologia'),
        fact('d', 'Technologia'),
      ]),
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 1400),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FavoriteCategoriesScreen(
          factsService: FactsService(),
          onFinished: () => finished++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, List<String> categories) async {
    for (final category in categories) {
      await tester.tap(find.text(category));
      await tester.pump();
    }
  }

  FilledButton doneButton(WidgetTester tester) {
    return tester.widget<FilledButton>(find.byType(FilledButton));
  }

  testWidgets('starts with nothing chosen and asks for 3', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Wybierz jeszcze 3'), findsOneWidget);
    expect(doneButton(tester).onPressed, isNull);
  });

  testWidgets('counts down and unlocks at 3', (tester) async {
    await pumpScreen(tester);

    await choose(tester, ['Kosmos', 'Historia']);
    expect(find.text('Wybierz jeszcze 1'), findsOneWidget);

    await choose(tester, ['Psychologia']);
    expect(find.text('Gotowe'), findsOneWidget);
    expect(doneButton(tester).onPressed, isNotNull);
  });

  testWidgets('tapping a chosen category takes it back', (tester) async {
    await pumpScreen(tester);

    await choose(tester, ['Kosmos', 'Kosmos']);

    expect(find.text('Wybierz jeszcze 3'), findsOneWidget);
  });

  testWidgets('saves the choice and explains the settings first', (
    tester,
  ) async {
    await pumpScreen(tester);
    await choose(tester, ['Kosmos', 'Historia', 'Psychologia']);

    await tester.tap(find.text('Gotowe'));
    await tester.pumpAndSettle();

    expect(find.textContaining('w ustawieniach'), findsOneWidget);
    expect(finished, 0);
    final disabled = await const CategoryPreferencesService().getDisabled();
    expect(disabled, contains('Technologia'));
    expect(disabled, isNot(contains('Kosmos')));

    await tester.tap(find.text('Rozumiem'));
    await tester.pumpAndSettle();

    expect(finished, 1);
  });

  testWidgets('choosing all keeps every category on', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Chcę wszystkie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozumiem'));
    await tester.pumpAndSettle();

    expect(await const CategoryPreferencesService().getDisabled(), isEmpty);
    expect(finished, 1);
  });

  testWidgets('an update shows newly bundled categories too', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Absurdy Prawa'), findsOneWidget);
  });

  testWidgets('fits a small phone with all categories', (tester) async {
    SharedPreferences.setMockInitialValues(
      storedFacts([
        for (var i = 0; i < 12; i++)
          fact('fakt-$i', 'Długa nazwa kategorii numer $i'),
      ]),
    );

    await pumpScreen(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.text('Wybierz jeszcze 3'), findsOneWidget);
  });
}
