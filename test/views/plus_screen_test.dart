import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/models/app_accent.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/store_purchase.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/purchase_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/celebration_overlay.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:dziesiatka/views/offer_scope.dart';
import 'package:dziesiatka/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_store.dart';

class _FakeAppInfoService extends AppInfoService {
  const _FakeAppInfoService();

  @override
  Future<String> getVersion() async => '1.4.0';
}

void main() {
  late FakeStore store;
  late PurchaseService purchases;
  late ThemeService themeService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
    store = FakeStore();
    themeService = ThemeService();
  });

  Future<void> connect(WidgetTester tester) async {
    purchases = PurchaseService(store: store);
    addTearDown(purchases.dispose);
    await purchases.loadOwned();
    await purchases.connect();
    await tester.pump();
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SettingsScreen(
          themeService: themeService,
          purchaseService: purchases,
          appInfoService: const _FakeAppInfoService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPlus(WidgetTester tester) async {
    await tester.tap(find.text('Dziesiątka+').last);
    await tester.pumpAndSettle();
  }

  testWidgets('the screen lists benefits and the store price', (tester) async {
    await connect(tester);
    await pumpSettings(tester);

    await openPlus(tester);

    expect(find.text('Bez poleceń partnerskich'), findsOneWidget);
    expect(find.text('Więcej kolorów'), findsOneWidget);
    expect(find.text('Kolejne funkcje bez dopłat'), findsOneWidget);
    expect(find.text('Kup za 14,99 zł'), findsOneWidget);
    expect(find.text('Przywróć zakup'), findsOneWidget);
  });

  testWidgets('a missing product hides the whole section', (tester) async {
    store.products = {...PurchaseService.tipIds};
    await connect(tester);

    await pumpSettings(tester);

    expect(find.text('Dziesiątka+'), findsNothing);
    expect(find.text('Kolor akcentu'), findsNothing);
  });

  testWidgets('no store, as on the web, hides the section', (tester) async {
    store.isOnline = false;
    await connect(tester);

    await pumpSettings(tester);

    expect(find.text('Dziesiątka+'), findsNothing);
  });

  testWidgets('a purchase thanks and celebrates', (tester) async {
    await connect(tester);
    await pumpSettings(tester);
    await openPlus(tester);

    await tester.tap(find.text('Kup za 14,99 zł'));
    await tester.pump();
    expect(store.bought, [PurchaseService.plusId]);

    store.complete(PurchaseService.plusId);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CelebrationOverlay), findsOneWidget);
    expect(find.text('Masz Dziesiątkę+. Dziękujemy!'), findsOneWidget);
    expect(find.textContaining('Kup za'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a pending payment says it waits', (tester) async {
    await connect(tester);
    await pumpSettings(tester);
    await openPlus(tester);

    await tester.tap(find.text('Kup za 14,99 zł'));
    store.complete(PurchaseService.plusId, status: StorePurchaseStatus.pending);
    await tester.pump();
    await tester.pump();

    expect(find.text('Płatność czeka na potwierdzenie'), findsOneWidget);
    expect(find.textContaining('włączy się sama'), findsOneWidget);
  });

  testWidgets('restoring brings Dziesiątka+ back', (tester) async {
    await connect(tester);
    await pumpSettings(tester);
    await openPlus(tester);
    store.owned.add(PurchaseService.plusId);

    await tester.tap(find.text('Przywróć zakup'));
    await tester.pump();
    await tester.pump();

    expect(purchases.hasPlus, isTrue);
    expect(find.text('Masz Dziesiątkę+. Dziękujemy!'), findsOneWidget);
  });

  testWidgets('accents show only with Dziesiątka+', (tester) async {
    await connect(tester);
    await pumpSettings(tester);
    expect(find.text('Kolor akcentu'), findsNothing);

    store.complete(PurchaseService.plusId);
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morski'));
    await tester.pumpAndSettle();

    expect(find.text('Kolor akcentu'), findsOneWidget);
    expect(themeService.accent, AppAccent.teal);
  });

  test('a saved accent stays off without Dziesiątka+', () {
    final service = ThemeService();
    service.setAccent(AppAccent.rose);

    expect(service.accentFor(hasPlus: true), AppAccent.rose);
    expect(service.accentFor(hasPlus: false), AppAccent.standard);
  });

  group('in the app', () {
    final fact = Fact(
      id: 'fact-1',
      title: 'Wenus',
      category: 'Kosmos',
      shortText: 'Krótko',
      longText: 'Rozwinięcie',
      sourceLabel: 'NASA',
      offer: const FactOffer(
        product: 'Atlas nieba',
        shop: 'Księgarnia',
        url: 'https://example.com/atlas',
      ),
      createdAt: DateTime.utc(2026),
    );

    Future<BuildContext> pumpApp(WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DziesiatkaApp(themeService: themeService, purchaseService: purchases),
      );
      await tester.pumpAndSettle();
      return tester.element(find.byType(Scaffold).first);
    }

    testWidgets('Dziesiątka+ hides partner offers', (tester) async {
      SharedPreferences.setMockInitialValues({'plusOwned': true});
      await connect(tester);
      final context = await pumpApp(tester);

      expect(OfferScope.offerFor(context, fact), isNull);
      FactDetailsSheet.show(context, fact);
      await tester.pumpAndSettle();
      expect(find.text('Polecamy'), findsNothing);
      expect(find.text('Rozwinięcie'), findsOneWidget);
    });

    testWidgets('without it the offer shows', (tester) async {
      await connect(tester);
      final context = await pumpApp(tester);

      expect(OfferScope.offerFor(context, fact), isNotNull);
    });

    testWidgets('the accent applies with Dziesiątka+', (tester) async {
      SharedPreferences.setMockInitialValues({
        'plusOwned': true,
        'themeAccent': 'forest',
      });
      await themeService.load();
      await connect(tester);
      final context = await pumpApp(tester);

      expect(
        Theme.of(context).colorScheme.primary,
        AppTheme.of(AppAccent.forest, Brightness.light).colorScheme.primary,
      );
    });
  });
}
