import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/fact_card.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:dziesiatka/views/favorites_screen.dart';
import 'package:dziesiatka/views/offer_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stored_facts.dart';

void main() {
  final now = DateTime(2026, 11, 22, 12);
  final plain = Fact(
    id: 'fact-1',
    title: 'Dzień dłuższy niż rok',
    category: 'Kosmos',
    shortText: 'Jeden obrót Wenus trwa dłużej niż rok.',
    longText: 'Rozwinięcie',
    sourceLabel: 'NASA',
    createdAt: DateTime.utc(2026),
  );

  Fact withOffer({String? until}) {
    return plain.copyWith(
      offer: FactOffer(
        product: 'Atlas nieba',
        shop: 'Księgarnia',
        url: 'https://example.com/atlas',
        until: until,
      ),
    );
  }

  Future<List<String>> pump(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, app) =>
            OfferScope(onOpened: opened.add, now: () => now, child: app!),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  Widget card(Fact fact) => FactCard(fact: fact, onExpand: () {});

  group('card', () {
    testWidgets('marks a fact with an offer as Partner', (tester) async {
      await pump(tester, card(withOffer()));

      expect(find.text('Partner'), findsOneWidget);
      expect(find.text('Sponsorowane'), findsNothing);
    });

    testWidgets('a fact without an offer has no badge', (tester) async {
      await pump(tester, card(plain));

      expect(find.text('Partner'), findsNothing);
    });

    testWidgets('an ended offer has no badge', (tester) async {
      await pump(tester, card(withOffer(until: '2026-11-21')));

      expect(find.text('Partner'), findsNothing);
    });
  });

  group('details', () {
    testWidgets('recommends the product under the source', (tester) async {
      await pump(tester, FactDetailsSheet(fact: withOffer()));

      expect(find.text('Polecamy'), findsOneWidget);
      expect(find.text('Atlas nieba · Księgarnia'), findsOneWidget);
      expect(find.textContaining('Link partnerski'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Polecamy')).dy,
        greaterThan(tester.getTopLeft(find.text('Źródło')).dy),
      );
    });

    testWidgets('a tap is reported with the fact id only', (tester) async {
      final opened = await pump(tester, FactDetailsSheet(fact: withOffer()));

      await tester.tap(find.text('Atlas nieba · Księgarnia'));
      await tester.pumpAndSettle();

      expect(opened, ['fact-1']);
    });

    testWidgets('an ended offer shows nothing', (tester) async {
      await pump(
        tester,
        FactDetailsSheet(fact: withOffer(until: '2026-11-21')),
      );

      expect(find.text('Polecamy'), findsNothing);
    });
  });

  group('partner card', () {
    Fact partner({String? until}) {
      return withOffer(
        until: until,
      ).copyWith(kind: FactKind.partner, category: FactKind.partnerCategory);
    }

    const button = 'Atlas nieba · Księgarnia ›';

    testWidgets('is labelled in place of a category', (tester) async {
      await pump(tester, card(partner()));

      expect(find.text('Ciekawostka partnerska'), findsOneWidget);
      expect(find.text('Partner'), findsNothing);
    });

    testWidgets('keeps the label after the offer ends', (tester) async {
      await pump(tester, card(partner(until: '2026-11-21')));

      expect(find.text('Ciekawostka partnerska'), findsOneWidget);
      expect(find.text(button), findsNothing);
    });

    testWidgets('has a button to the product under the text', (tester) async {
      final opened = await pump(tester, card(partner()));

      final size = tester.getSize(find.widgetWithText(FilledButton, button));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(
        tester.getTopLeft(find.text(button)).dy,
        greaterThan(tester.getBottomLeft(find.text(plain.shortText)).dy),
      );

      await tester.tap(find.text(button));
      await tester.pumpAndSettle();

      expect(opened, ['fact-1']);
    });

    testWidgets('a regular card with an offer has no button', (tester) async {
      await pump(tester, card(withOffer()));

      expect(find.textContaining('›'), findsNothing);
    });

    testWidgets('a swipe that starts on the button moves the card', (
      tester,
    ) async {
      var swiped = 0;
      final opened = await pump(
        tester,
        GestureDetector(
          onHorizontalDragEnd: (_) => swiped++,
          child: card(partner()),
        ),
      );

      await tester.drag(find.text(button), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(swiped, 1);
      expect(opened, isEmpty);
    });

    testWidgets('details show the product and the partner note', (
      tester,
    ) async {
      await pump(tester, FactDetailsSheet(fact: partner()));

      expect(find.text('Ciekawostka partnerska'), findsOneWidget);
      expect(find.text('Produkt partnera'), findsOneWidget);
      expect(find.text('Źródło'), findsOneWidget);
      expect(find.text('Atlas nieba · Księgarnia'), findsOneWidget);
      expect(
        find.text(
          'Link partnerski – kupując przez niego, wspierasz Dziesiątkę '
          'bez dopłat.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an ended partner card leaves the favorites', (tester) async {
      SharedPreferences.setMockInitialValues(
        storedFacts([
          partner(until: '2026-11-21').copyWith(id: 'old', isFavorite: true),
          partner().copyWith(id: 'new', title: 'Aktualna', isFavorite: true),
        ]),
      );

      await pump(tester, FavoritesScreen(factsService: FactsService()));

      expect(find.text('Aktualna'), findsOneWidget);
      expect(find.text(plain.title), findsNothing);
    });
  });
}
