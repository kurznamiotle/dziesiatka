import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:dziesiatka/views/favorites_screen.dart';
import 'package:dziesiatka/views/share_card_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final fact = Fact(
    id: 'seed-001',
    title: 'Dzień dłuższy niż rok',
    category: 'Kosmos',
    shortText: 'Jeden obrót Wenus trwa dłużej niż rok.',
    longText: 'Rozwinięcie',
    source: 'Źródło',
    isFavorite: true,
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'facts': jsonEncode([fact.toJson()]),
    });
  });

  Future<void> pumpFavorites(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FavoritesScreen(factsService: FactsService()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a favorite opens the share preview', (tester) async {
    await pumpFavorites(tester);

    await tester.tap(find.byTooltip('Udostępnij'));
    await tester.pumpAndSettle();

    expect(find.byType(ShareCardSheet), findsOneWidget);
    expect(find.byType(FactDetailsSheet), findsNothing);
  });

  testWidgets('sharing does not remove the favorite', (tester) async {
    await pumpFavorites(tester);

    await tester.tap(find.byTooltip('Udostępnij'));
    await tester.pumpAndSettle();

    expect((await FactsService().getFacts()).single.isFavorite, isTrue);
  });

  testWidgets('the details sheet opens the share preview', (tester) async {
    await pumpFavorites(tester);

    await tester.tap(find.text(fact.title));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(FactDetailsSheet),
        matching: find.byTooltip('Udostępnij'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ShareCardSheet), findsOneWidget);
    expect(find.text('Udostępnij grafikę'), findsOneWidget);
  });
}
