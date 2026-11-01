import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';

const _pagePadding = 24.0;
const _statusBar = 47.0;
const _gestureBar = 34.0;
const _phone = Size(390, 844);

void main() {
  final mobilePlatforms = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The cached asset future belongs to the previous test's fake async zone
    // and would never complete in this one.
    rootBundle.clear();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = _phone,
    FakeViewPadding insets = FakeViewPadding.zero,
    ThemeService? themeService,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DziesiatkaApp(
        themeService: themeService ?? ThemeService(),
        random: const KeepOrderRandom(),
      ),
    );
    await tester.pumpAndSettle();
  }

  double headerLeft(WidgetTester tester) {
    return tester.getTopLeft(find.text('Dziesiątka')).dx;
  }

  group('frame', () {
    testWidgets(
      'wide desktop windows center a 440px frame',
      (tester) async {
        await pumpApp(tester, size: const Size(1200, 900));

        expect(headerLeft(tester), (1200 - 440) / 2 + _pagePadding);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets(
      'narrow desktop windows use the full width',
      (tester) async {
        await pumpApp(tester);

        expect(headerLeft(tester), _pagePadding);
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('mobile apps fill wide screens', (tester) async {
      const tablet = Size(1200, 900);
      await pumpApp(tester, size: tablet);

      expect(headerLeft(tester), _pagePadding);
      expect(
        tester.getBottomRight(find.text('Polub')).dy,
        greaterThan(tablet.height - 2 * _pagePadding - 56),
      );
    }, variant: mobilePlatforms);
  });

  group('status bar icons', () {
    Brightness? iconBrightness(WidgetTester tester) {
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      return region.value.statusBarIconBrightness;
    }

    testWidgets('are dark in the light theme', (tester) async {
      await pumpApp(tester);

      expect(iconBrightness(tester), Brightness.dark);
    }, variant: mobilePlatforms);

    testWidgets('are light in the dark theme', (tester) async {
      final themeService = ThemeService();
      await themeService.setThemeMode(ThemeMode.dark);

      await pumpApp(tester, themeService: themeService);

      expect(iconBrightness(tester), Brightness.light);
    }, variant: mobilePlatforms);
  });

  group('system insets', () {
    const portraitInsets = FakeViewPadding(
      top: _statusBar,
      bottom: _gestureBar,
    );

    testWidgets('the home screen stays clear of both bars', (tester) async {
      await pumpApp(tester, insets: portraitInsets);

      expect(
        tester.getTopLeft(find.text('Dziesiątka')).dy,
        greaterThanOrEqualTo(_statusBar),
      );
      expect(
        tester.getBottomLeft(find.text('Polub')).dy,
        lessThanOrEqualTo(_phone.height - _gestureBar),
      );
    });

    testWidgets('the home screen stays clear of a side camera cutout', (
      tester,
    ) async {
      const cutout = 44.0;
      await pumpApp(
        tester,
        size: const Size(844, 390),
        insets: const FakeViewPadding(left: cutout, right: cutout),
      );

      expect(headerLeft(tester), cutout + _pagePadding);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the details sheet ends above the gesture bar', (tester) async {
      await pumpApp(tester, insets: portraitInsets);

      await tester.tap(find.text('Dowiedz się więcej').last);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(FactDetailsSheet), const Offset(0, -3000));
      await tester.pumpAndSettle();

      final source = find.text('NASA');
      expect(
        tester.getBottomLeft(source).dy,
        lessThanOrEqualTo(_phone.height - _gestureBar),
      );
    });

    testWidgets('the favorites list ends above the gesture bar', (
      tester,
    ) async {
      const short = Size(390, 600);
      final service = FactsService();
      final facts = await service.getFacts();
      for (final fact in facts) {
        await service.toggleFavorite(fact.id);
      }
      await pumpApp(tester, size: short, insets: portraitInsets);

      await tester.tap(find.byTooltip('Ulubione'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(facts.last.title), 500);
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(
        tester.getBottomLeft(find.text(facts.last.title)).dy,
        lessThanOrEqualTo(short.height - _gestureBar),
      );
    });
  });
}
