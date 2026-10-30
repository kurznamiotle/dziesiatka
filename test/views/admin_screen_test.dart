import 'package:dziesiatka/services/backup_service.dart';
import 'package:dziesiatka/services/categories_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The cached asset future belongs to the previous test's fake async zone
    // and would never complete in this one.
    rootBundle.clear();
  });

  Future<void> pumpAdmin(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AdminScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> selectCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> fillTextFields(WidgetTester tester, {String? source}) async {
    final fields = {
      'Nagłówek': 'Nowy fakt',
      'Tekst krótki (zajawka na fiszkę)': 'Zajawka',
      'Tekst długi (rozwinięcie)': 'Rozwinięcie',
      'Źródło (link lub nazwa publikacji)': source ?? 'Nature, 2020',
    };
    for (final entry in fields.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, entry.key),
        entry.value,
      );
    }
  }

  testWidgets('the form shows errors and saves nothing when empty', (
    tester,
  ) async {
    await pumpAdmin(tester);

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(find.text('To pole jest wymagane.'), findsNWidgets(4));
    expect(find.text('Wybierz kategorię.'), findsOneWidget);
    expect(await FactsService().getFacts(), hasLength(10));
  });

  testWidgets('the form rejects a malformed link', (tester) async {
    await pumpAdmin(tester);
    await fillTextFields(tester, source: 'https://');
    await selectCategory(tester, 'Kosmos');

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(find.text('To nie jest poprawny link.'), findsOneWidget);
    expect(await FactsService().getFacts(), hasLength(10));
  });

  testWidgets('a valid fact is saved and the form clears', (tester) async {
    await pumpAdmin(tester);
    await fillTextFields(tester);
    await selectCategory(tester, 'Historia');

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    final saved = (await FactsService().getFacts()).last;
    expect(saved.title, 'Nowy fakt');
    expect(saved.category, 'Historia');
    expect(saved.shortText, 'Zajawka');
    expect(saved.longText, 'Rozwinięcie');
    expect(saved.source, 'Nature, 2020');
    expect(find.text('Nowy fakt'), findsNothing);
    expect(find.text('Dodano ciekawostkę.'), findsOneWidget);
  });

  testWidgets('a new category is stored and selected', (tester) async {
    await pumpAdmin(tester);
    await fillTextFields(tester);

    await selectCategory(tester, '+ Dodaj nową kategorię');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nazwa kategorii'),
      'Muzyka',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Dodaj'));
    await tester.pumpAndSettle();

    expect(await CategoriesService().getCategories(), contains('Muzyka'));

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect((await FactsService().getFacts()).last.category, 'Muzyka');
  });

  testWidgets('cancelling a new category keeps the previous selection', (
    tester,
  ) async {
    await pumpAdmin(tester);
    await fillTextFields(tester);
    await selectCategory(tester, 'Kosmos');

    await selectCategory(tester, '+ Dodaj nową kategorię');
    await tester.tap(find.widgetWithText(TextButton, 'Anuluj'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect((await FactsService().getFacts()).last.category, 'Kosmos');
  });

  testWidgets('the fact list previews and deletes after confirming', (
    tester,
  ) async {
    await pumpAdmin(tester);
    final newest = (await FactsService().getFacts()).last;
    await openTab(tester, 'Fakty');

    await tester.tap(find.text(newest.title));
    await tester.pumpAndSettle();
    expect(find.text(newest.longText), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Usuń').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Anuluj'));
    await tester.pumpAndSettle();
    expect(await FactsService().getFacts(), hasLength(10));

    await tester.tap(find.byTooltip('Usuń').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
    await tester.pumpAndSettle();

    final facts = await FactsService().getFacts();
    expect(facts, hasLength(9));
    expect(facts.map((fact) => fact.id), isNot(contains(newest.id)));
    expect(find.text(newest.title), findsNothing);
  });

  testWidgets('copying the export writes it to the clipboard', (tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpAdmin(tester);
    await openTab(tester, 'Dane');

    await tester.tap(find.text('Kopiuj do schowka'));
    await tester.pumpAndSettle();

    expect(clipboard, contains('"shortText"'));
    expect(find.text('Skopiowano JSON do schowka.'), findsOneWidget);
  });

  testWidgets('an invalid import shows an error and changes nothing', (
    tester,
  ) async {
    await pumpAdmin(tester);
    await openTab(tester, 'Dane');

    await tester.enterText(
      find.widgetWithText(TextField, 'Wklej JSON z eksportu'),
      '{"facts": []}',
    );
    await tester.tap(find.text('Importuj i zastąp bazę'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Brakuje list'), findsOneWidget);
    expect(find.text('Zastąpić całą bazę?'), findsNothing);
    expect(await FactsService().getFacts(), hasLength(10));
  });

  testWidgets('a confirmed import replaces the database', (tester) async {
    final facts = FactsService();
    final categories = CategoriesService();
    final backup = BackupService(facts, categories);
    await pumpAdmin(tester);
    await categories.addCategory('Muzyka');
    await facts.deleteFact('seed-001');
    final exported = await backup.exportJson();
    await facts.replaceFacts([]);
    await openTab(tester, 'Dane');

    await tester.enterText(
      find.widgetWithText(TextField, 'Wklej JSON z eksportu'),
      exported,
    );
    await tester.tap(find.text('Importuj i zastąp bazę'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Zastąp'));
    await tester.pumpAndSettle();

    expect(await facts.getFacts(), hasLength(9));
    expect(await categories.getCategories(), contains('Muzyka'));
    expect(find.text('Zaimportowano bazę.'), findsOneWidget);
  });
}
