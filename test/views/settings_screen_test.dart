import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/link_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLinkService extends LinkService {
  _FakeLinkService({this.opens = true});

  final bool opens;
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return opens;
  }
}

class _FakeAppInfoService extends AppInfoService {
  const _FakeAppInfoService({this.fails = false});

  final bool fails;

  @override
  Future<String> getVersion() async {
    if (fails) throw StateError('brak');
    return '1.2.3';
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The cached asset future belongs to the previous test's fake async zone
    // and would never complete in this one.
    rootBundle.clear();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    LinkService linkService = const LinkService(),
    AppInfoService appInfoService = const _FakeAppInfoService(),
    String? buyCoffeeUrl,
    String? becomeEditorUrl,
    ThemeService? themeService,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SettingsScreen(
          themeService: themeService ?? ThemeService(),
          linkService: linkService,
          appInfoService: appInfoService,
          buyCoffeeUrl: buyCoffeeUrl,
          becomeEditorUrl: becomeEditorUrl,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ListTile tile(WidgetTester tester, String title) {
    return tester.widget<ListTile>(
      find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
    );
  }

  group('in the app', () {
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

    testWidgets('the gear opens settings and a theme applies', (tester) async {
      final service = ThemeService();
      await pumpApp(tester, service);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(activeBrightness(tester), Brightness.light);

      await tester.tap(find.byTooltip('Ustawienia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ciemny'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(service.themeMode, ThemeMode.dark);
      expect(activeBrightness(tester), Brightness.dark);
    });

    testWidgets('the system mode follows the platform brightness', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await pumpApp(tester, ThemeService());

      expect(activeBrightness(tester), Brightness.dark);
    });

    testWidgets('a saved dark theme applies on the first frame', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
      final service = ThemeService();
      await service.load();

      await pumpApp(tester, service);

      expect(activeBrightness(tester), Brightness.dark);
    });
  });

  testWidgets('shows all sections', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Wygląd'), findsOneWidget);
    expect(find.text('Wsparcie i rozwój'), findsOneWidget);
    expect(find.text('O aplikacji'), findsOneWidget);
  });

  testWidgets('marks the current theme and changes it', (tester) async {
    final service = ThemeService();
    await pumpSettings(tester, themeService: service);
    expect(tile(tester, 'Zgodny z systemem').selected, isTrue);
    expect(tile(tester, 'Jasny').selected, isFalse);

    await tester.tap(find.text('Jasny'));
    await tester.pumpAndSettle();

    expect(service.themeMode, ThemeMode.light);
    expect(tile(tester, 'Jasny').selected, isTrue);
    expect(tile(tester, 'Zgodny z systemem').selected, isFalse);
  });

  testWidgets('links without an address are disabled', (tester) async {
    final links = _FakeLinkService();
    await pumpSettings(tester, linkService: links);

    expect(find.text('Wkrótce'), findsNWidgets(2));
    expect(tile(tester, 'Postaw kawę twórcy ☕').enabled, isFalse);

    await tester.tap(find.text('Postaw kawę twórcy ☕'));
    await tester.pumpAndSettle();

    expect(links.opened, isEmpty);
  });

  testWidgets('links with an address open through the link service', (
    tester,
  ) async {
    final links = _FakeLinkService();
    await pumpSettings(
      tester,
      linkService: links,
      buyCoffeeUrl: 'https://example.com/kawa',
      becomeEditorUrl: 'mailto:redakcja@example.com',
    );

    await tester.tap(find.text('Postaw kawę twórcy ☕'));
    await tester.tap(find.text('Zostań redaktorem ✍️'));
    await tester.pumpAndSettle();

    expect(find.text('Wkrótce'), findsNothing);
    expect(links.opened, [
      'https://example.com/kawa',
      'mailto:redakcja@example.com',
    ]);
  });

  testWidgets('a link that fails to open shows a message', (tester) async {
    await pumpSettings(
      tester,
      linkService: _FakeLinkService(opens: false),
      buyCoffeeUrl: 'https://example.com/kawa',
    );

    await tester.tap(find.text('Postaw kawę twórcy ☕'));
    await tester.pumpAndSettle();

    expect(find.text('Nie udało się otworzyć linku.'), findsOneWidget);
  });

  testWidgets('shows the app version', (tester) async {
    await pumpSettings(tester);

    expect(find.text('1.2.3'), findsOneWidget);
  });

  testWidgets('keeps working when the version is unavailable', (tester) async {
    await pumpSettings(
      tester,
      appInfoService: const _FakeAppInfoService(fails: true),
    );

    expect(find.text('Wersja'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the privacy policy', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Polityka prywatności'));
    await tester.pumpAndSettle();

    expect(find.textContaining('nie zbiera danych osobowych'), findsOneWidget);
  });

  testWidgets('opens the license page', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Licencje'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
