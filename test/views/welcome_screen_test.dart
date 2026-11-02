import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/onboarding_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:dziesiatka/views/favorite_categories_screen.dart';
import 'package:dziesiatka/views/home_screen.dart';
import 'package:dziesiatka/views/usage_consent_dialog.dart';
import 'package:dziesiatka/views/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DziesiatkaApp(themeService: ThemeService(), showWelcome: true),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
  }

  testWidgets('the instructions explain where quiz answers are', (
    tester,
  ) async {
    await pumpApp(tester);

    await tapNext(tester);
    await tapNext(tester);

    expect(
      find.text('Odpowiedzi do quizu często są widoczne dopiero tutaj.'),
      findsOneWidget,
    );
  });

  Future<void> chooseCategoriesAndConfirm(WidgetTester tester) async {
    await tester.pumpAndSettle();
    for (final category in ['Kosmos', 'Historia', 'Psychologia']) {
      await tester.tap(find.text(category));
      await tester.pump();
    }
    await tester.tap(find.text('Gotowe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozumiem'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('finishing the last page leads through categories to the deck', (
    tester,
  ) async {
    await pumpApp(tester);

    await tapNext(tester);
    await tapNext(tester);
    await tapNext(tester);
    await tester.tap(find.text('Zaczynamy'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoriteCategoriesScreen), findsOneWidget);
    expect(await const OnboardingService().shouldShowWelcome(), isTrue);

    await chooseCategoriesAndConfirm(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(await const OnboardingService().shouldShowWelcome(), isFalse);
  });

  testWidgets('a web visitor is asked about statistics before the deck', (
    tester,
  ) async {
    final usageService = UsageService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      asksForConsent: true,
      client: MockClient((_) async => http.Response('', 204)),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DziesiatkaApp(
        themeService: ThemeService(),
        usageService: usageService,
        showWelcome: true,
      ),
    );
    await tester.pumpAndSettle();
    await tapNext(tester);
    await tapNext(tester);
    await tapNext(tester);
    await tester.tap(find.text('Zaczynamy'));
    await tester.pumpAndSettle();

    await chooseCategoriesAndConfirm(tester);
    await tester.pumpAndSettle();

    expect(find.byType(UsageConsentDialog), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.text('Nie zgadzam się'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(await usageService.isEnabled(), isFalse);
    expect(await usageService.needsConsent(), isFalse);
  });

  testWidgets('skipping the instructions still offers the categories', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Pomiń'));
    await tester.pumpAndSettle();

    expect(find.byType(FavoriteCategoriesScreen), findsOneWidget);

    await chooseCategoriesAndConfirm(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(await const OnboardingService().shouldShowWelcome(), isFalse);
  });

  testWidgets('a new user can choose from all 12 bundled categories', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Pomiń'));
    await tester.pumpAndSettle();

    expect(find.text('Absurdy Prawa'), findsOneWidget);
    expect(find.text('Kosmos'), findsOneWidget);
    expect(find.byType(InkWell), findsAtLeastNWidgets(12));
  });

  testWidgets('the app starts on the deck without the welcome flag', (
    tester,
  ) async {
    await tester.pumpWidget(DziesiatkaApp(themeService: ThemeService()));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('finishing calls back only on the last page', (tester) async {
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: WelcomeScreen(onFinished: () => finished++)),
    );

    await tapNext(tester);
    expect(finished, 0);

    await tester.tap(find.text('Pomiń'));
    expect(finished, 1);
  });
}
