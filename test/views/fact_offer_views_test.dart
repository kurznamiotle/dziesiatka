import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/fact_card.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:dziesiatka/views/offer_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<List<String>> pump(
    WidgetTester tester,
    Widget child, {
    bool isHidden = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, app) => OfferScope(
          isHidden: isHidden,
          onOpened: opened.add,
          now: () => now,
          child: app!,
        ),
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

    testWidgets('Dziesiątka+ hides the badge', (tester) async {
      await pump(tester, card(withOffer()), isHidden: true);

      expect(find.text('Partner'), findsNothing);
      expect(find.text(plain.title), findsOneWidget);
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

    testWidgets('Dziesiątka+ hides the section and keeps the fact', (
      tester,
    ) async {
      await pump(tester, FactDetailsSheet(fact: withOffer()), isHidden: true);

      expect(find.text('Polecamy'), findsNothing);
      expect(find.textContaining('Link partnerski'), findsNothing);
      expect(find.text('Rozwinięcie'), findsOneWidget);
    });

    testWidgets('an ended offer shows nothing', (tester) async {
      await pump(
        tester,
        FactDetailsSheet(fact: withOffer(until: '2026-11-21')),
      );

      expect(find.text('Polecamy'), findsNothing);
    });
  });
}
