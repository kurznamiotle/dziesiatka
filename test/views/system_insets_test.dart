import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';

const _screen = Size(390, 844);

/// The system bars an edge-to-edge app draws under on Android.
enum _Navigation {
  gestures(top: 24, bottom: 24),
  threeButtons(top: 24, bottom: 48);

  const _Navigation({required this.top, required this.bottom});

  final double top;
  final double bottom;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
  });

  for (final navigation in _Navigation.values) {
    group('with ${navigation.name} navigation', () {
      Future<void> pumpApp(
        WidgetTester tester, {
        bool showWelcome = false,
      }) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = _screen;
        final insets = FakeViewPadding(
          top: navigation.top,
          bottom: navigation.bottom,
        );
        tester.view.padding = insets;
        tester.view.viewPadding = insets;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          DziesiatkaApp(
            themeService: ThemeService(),
            showWelcome: showWelcome,
            random: const KeepOrderRandom(),
          ),
        );
        await tester.pumpAndSettle();
      }

      void expectClearOfBars(WidgetTester tester, Finder finder) {
        expect(finder, findsWidgets);
        for (final element in finder.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget).first);
          expect(
            rect.top,
            greaterThanOrEqualTo(navigation.top),
            reason: '${element.widget} under the status bar',
          );
          expect(
            rect.bottom,
            lessThanOrEqualTo(_screen.height - navigation.bottom),
            reason: '${element.widget} under the navigation bar',
          );
        }
      }

      Future<void> scrollTo(WidgetTester tester, Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
      }

      testWidgets('the welcome screen', (tester) async {
        await pumpApp(tester, showWelcome: true);

        expectClearOfBars(tester, find.text('Pomiń'));
        expectClearOfBars(tester, find.text('Dalej'));
      });

      testWidgets('the deck', (tester) async {
        await pumpApp(tester);

        expectClearOfBars(tester, find.text('Dziesiątka'));
        expectClearOfBars(tester, find.text('Dalej'));
        expectClearOfBars(tester, find.text('Polub'));
        expectClearOfBars(tester, find.byTooltip('Cofnij'));
      });

      testWidgets('the details sheet', (tester) async {
        await pumpApp(tester);

        await tester.tap(find.text('Dowiedz się więcej').last);
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text('Zgłoś błąd'));

        expect(find.byType(FactDetailsSheet), findsOneWidget);
        expectClearOfBars(tester, find.text('Zgłoś błąd'));
      });

      testWidgets('the screen before the quiz, the quiz and the summary', (
        tester,
      ) async {
        await pumpApp(tester);
        for (var i = 0; i < 9; i++) {
          await tester.tap(find.text('Dalej'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Dalej'));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expectClearOfBars(tester, find.text('Przejdź do quizu'));
        expectClearOfBars(tester, find.text('Cofnij'));

        await tester.tap(find.text('Przejdź do quizu'));
        await tester.pumpAndSettle();

        expectClearOfBars(tester, find.textContaining(RegExp(r'^[ABC]\. ')));
        expectClearOfBars(tester, find.text('Przypomnij sobie'));

        for (var i = 0; i < 4; i++) {
          await tester.tap(find.textContaining(RegExp(r'^A\. ')));
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
        }
        await scrollTo(tester, find.text('Powtórz dzisiejszą talię'));

        expectClearOfBars(tester, find.text('Powtórz dzisiejszą talię'));
        expectClearOfBars(tester, find.text('Jeszcze 5'));
      });

      testWidgets('the settings', (tester) async {
        await pumpApp(tester);

        await tester.tap(find.byTooltip('Ustawienia'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Licencje'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        expectClearOfBars(tester, find.text('Licencje'));
      });
    });
  }

  group('system bar style on Android', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'sets only icon brightness in ${mode.name} mode',
        (tester) async {
          SharedPreferences.setMockInitialValues({'themeMode': mode.name});
          final themeService = ThemeService();
          await themeService.load();
          await tester.pumpWidget(
            DziesiatkaApp(
              themeService: themeService,
              random: const KeepOrderRandom(),
            ),
          );
          await tester.pumpAndSettle();

          final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
          );
          final style = region.value;

          expect(style.statusBarColor, isNull);
          expect(style.systemNavigationBarColor, isNull);
          expect(style.systemNavigationBarDividerColor, isNull);
          expect(
            style.statusBarIconBrightness,
            mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
          );
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );
    }
  });
}
