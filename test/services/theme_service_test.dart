import 'package:dziesiatka/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to the system theme', () async {
    final service = ThemeService();
    await service.load();

    expect(service.themeMode, ThemeMode.system);
  });

  test('the chosen theme survives a new service instance', () async {
    await ThemeService().setThemeMode(ThemeMode.dark);

    final reloaded = ThemeService();
    await reloaded.load();

    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('an unknown stored value falls back to the system theme', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'neon'});

    final service = ThemeService();
    await service.load();

    expect(service.themeMode, ThemeMode.system);
  });

  test('changing the theme notifies listeners', () async {
    final service = ThemeService();
    final seen = <ThemeMode>[];
    service.addListener(() => seen.add(service.themeMode));

    await service.setThemeMode(ThemeMode.dark);

    expect(seen, [ThemeMode.dark]);
  });
}
