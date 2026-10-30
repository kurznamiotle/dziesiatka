import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/theme_service.dart';
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

  Future<void> pumpApp(WidgetTester tester, ThemeService service) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DziesiatkaApp(themeService: service));
    await tester.pumpAndSettle();
  }

  Brightness activeBrightness(WidgetTester tester) {
    return Theme.of(tester.element(find.text('Dziesiątka'))).brightness;
  }

  testWidgets('the button cycles themes and updates its tooltip', (
    tester,
  ) async {
    await pumpApp(tester, ThemeService());
    expect(find.byTooltip('Motyw: zgodny z systemem'), findsOneWidget);
    expect(activeBrightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Motyw: zgodny z systemem'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Motyw: jasny'), findsOneWidget);
    expect(activeBrightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Motyw: jasny'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Motyw: ciemny'), findsOneWidget);
    expect(activeBrightness(tester), Brightness.dark);

    await tester.tap(find.byTooltip('Motyw: ciemny'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Motyw: zgodny z systemem'), findsOneWidget);
  });

  testWidgets('the system mode follows the platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester, ThemeService());

    expect(activeBrightness(tester), Brightness.dark);
  });

  testWidgets('a saved dark theme applies on the first frame', (tester) async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final service = ThemeService();
    await service.load();

    await pumpApp(tester, service);

    expect(activeBrightness(tester), Brightness.dark);
    expect(find.byTooltip('Motyw: ciemny'), findsOneWidget);
  });
}
