import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/category_preferences_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stored_facts.dart';

void main() {
  Fact fact(String id, String category, {bool isWithdrawn = false}) {
    return Fact(
      id: id,
      title: id,
      category: category,
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      sourceLabel: 'Źródło',
      isWithdrawn: isWithdrawn,
      createdAt: DateTime.utc(2026),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(
      storedFacts([
        fact('a', 'Kosmos'),
        fact('b', 'Historia'),
        fact('c', 'Psychologia'),
        fact('d', 'Technologia'),
        fact('e', 'Wycofana', isWithdrawn: true),
      ]),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CategoriesScreen(factsService: FactsService())),
    );
    await tester.pumpAndSettle();
  }

  SwitchListTile tile(WidgetTester tester, String category) {
    return tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, category),
    );
  }

  testWidgets('lists categories that still have facts', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Kosmos'), findsOneWidget);
    expect(find.text('Historia'), findsOneWidget);
    expect(find.text('Wycofana'), findsNothing);
  });

  testWidgets('turning a category off is saved', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Kosmos'));
    await tester.pumpAndSettle();

    expect(tile(tester, 'Kosmos').value, isFalse);
    expect(await const CategoryPreferencesService().getDisabled(), {'Kosmos'});
  });

  testWidgets('at least 3 categories stay chosen', (tester) async {
    await pumpScreen(tester);
    expect(tile(tester, 'Historia').onChanged, isNotNull);

    await tester.tap(find.text('Kosmos'));
    await tester.pumpAndSettle();

    expect(tile(tester, 'Historia').onChanged, isNull);
    expect(tile(tester, 'Psychologia').onChanged, isNull);
    expect(tile(tester, 'Technologia').onChanged, isNull);
    // The way back stays open.
    expect(tile(tester, 'Kosmos').onChanged, isNotNull);
  });

  testWidgets('a category that is off can be turned back on', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Kosmos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kosmos'));
    await tester.pumpAndSettle();

    expect(tile(tester, 'Kosmos').value, isTrue);
    expect(await const CategoryPreferencesService().getDisabled(), isEmpty);
  });
}
