import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/daily_deck_service.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/services/purchase_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/celebration_overlay.dart';
import 'package:dziesiatka/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_store.dart';
import '../helpers/keep_order_random.dart';

class _FakeAppInfoService extends AppInfoService {
  const _FakeAppInfoService();

  @override
  Future<String> getVersion() async => '1.4.0';
}

class _FakeLinkService extends LinkService {
  final opened = <String>[];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  late FakeStore store;
  late PurchaseService purchases;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
    store = FakeStore();
  });

  Future<void> connect(WidgetTester tester) async {
    purchases = PurchaseService(store: store);
    addTearDown(purchases.dispose);
    await purchases.loadOwned();
    await purchases.connect();
    await tester.pump();
  }

  group('settings', () {
    Future<_FakeLinkService> pumpSettings(
      WidgetTester tester, {
      PurchaseService? purchaseService,
      String? supportUrl,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1400);
      addTearDown(tester.view.reset);
      final links = _FakeLinkService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SettingsScreen(
            themeService: ThemeService(),
            purchaseService: purchaseService,
            linkService: links,
            appInfoService: const _FakeAppInfoService(),
            supportUrl: supportUrl,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return links;
    }

    testWidgets('a coffee opens the amounts from the store', (tester) async {
      await connect(tester);
      final links = await pumpSettings(tester, purchaseService: purchases);

      await tester.tap(find.text('Postaw kawę twórcy ☕'));
      await tester.pumpAndSettle();

      expect(find.text('Mała kawa · 5,00 zł'), findsOneWidget);
      expect(find.text('Duża kawa · 10,00 zł'), findsOneWidget);
      expect(find.text('Kawa z ciastkiem · 20,00 zł'), findsOneWidget);

      await tester.tap(find.text('Duża kawa · 10,00 zł'));
      await tester.pumpAndSettle();

      expect(store.bought, ['napiwek_sredni']);
      expect(links.opened, isEmpty);
    });

    testWidgets('with store tips there is no outside link', (tester) async {
      await connect(tester);

      await pumpSettings(
        tester,
        purchaseService: purchases,
        supportUrl: 'https://example.com/kawa',
      );

      expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
      expect(find.text('Postaw kawę twórcy ☕'), findsOneWidget);
    });

    testWidgets('on Android without tips the section is hidden', (
      tester,
    ) async {
      store.products = {};
      await connect(tester);

      await pumpSettings(tester, purchaseService: purchases);

      expect(find.text('Wsparcie i rozwój'), findsNothing);
      expect(find.text('Postaw kawę twórcy ☕'), findsNothing);
    });

    testWidgets('the web keeps the support link', (tester) async {
      final links = await pumpSettings(
        tester,
        purchaseService: PurchaseService(),
        supportUrl: 'https://example.com/kawa',
      );

      await tester.tap(find.text('Postaw kawę twórcy ☕'));
      await tester.pumpAndSettle();

      expect(links.opened, ['https://example.com/kawa']);
    });
  });

  group('invitation on the finished day', () {
    final now = DateTime(2026, 11, 22, 12);

    void givenStreak(int days) {
      SharedPreferences.setMockInitialValues({
        'streakCount': days,
        'streakLastCompleted': DailyDeck.dateKey(
          now.subtract(const Duration(days: 1)),
        ),
      });
    }

    Future<void> pumpApp(WidgetTester tester, DateTime Function() clock) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        DziesiatkaApp(
          themeService: ThemeService(),
          purchaseService: purchases,
          now: clock,
          random: const KeepOrderRandom(),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> finishDay(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('Dalej'));
        await tester.pumpAndSettle();
      }
      final toQuiz = find.textContaining('Przejdź do quizu');
      if (toQuiz.evaluate().isNotEmpty) {
        await tester.tap(toQuiz);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < DailyDeckService.quizQuestionCount; i++) {
        await tester.tap(find.textContaining(RegExp(r'^A\. ')));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    Finder invite() =>
        find.text('Tydzień z Dziesiątką! Postawisz kawę twórcy?');

    testWidgets('shows once after the 7th day and can be closed', (
      tester,
    ) async {
      givenStreak(6);
      await connect(tester);
      var clock = now;
      await pumpApp(tester, () => clock);

      await finishDay(tester);

      expect(find.text('Gratulacje!'), findsOneWidget);
      expect(invite(), findsOneWidget);

      await tester.tap(find.byTooltip('Zamknij'));
      await tester.pumpAndSettle();
      expect(invite(), findsNothing);

      clock = now.add(const Duration(days: 1));
      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester, () => clock);
      await finishDay(tester);
      expect(find.text('Gratulacje!'), findsOneWidget);
      expect(invite(), findsNothing);
    });

    testWidgets('not before the 7th day', (tester) async {
      givenStreak(5);
      await connect(tester);
      await pumpApp(tester, () => now);

      await finishDay(tester);

      expect(find.text('Gratulacje!'), findsOneWidget);
      expect(invite(), findsNothing);
    });

    testWidgets('not without tips in the store', (tester) async {
      givenStreak(6);
      store.products = {};
      await connect(tester);
      await pumpApp(tester, () => now);

      await finishDay(tester);

      expect(invite(), findsNothing);
    });

    testWidgets('a tip thanks and ends the invitation', (tester) async {
      givenStreak(6);
      await connect(tester);
      await pumpApp(tester, () => now);
      await finishDay(tester);

      await tester.tap(find.text('Postaw'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mała kawa · 5,00 zł'));
      await tester.pumpAndSettle();
      store.complete('napiwek_maly');
      await tester.pump();
      await tester.pump();

      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(invite(), findsNothing);
      expect(store.finished.single.consumed, isTrue);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tipInviteClosed'), isTrue);
    });
  });
}
