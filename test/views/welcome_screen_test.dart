import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/onboarding_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/home_screen.dart';
import 'package:dziesiatka/views/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
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

  testWidgets('finishing the last page opens the deck and is remembered', (
    tester,
  ) async {
    await pumpApp(tester);

    await tapNext(tester);
    await tapNext(tester);
    await tapNext(tester);
    await tester.tap(find.text('Zaczynamy'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(await const OnboardingService().shouldShowWelcome(), isFalse);
  });

  testWidgets('skipping also opens the deck and is remembered', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Pomiń'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(await const OnboardingService().shouldShowWelcome(), isFalse);
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
