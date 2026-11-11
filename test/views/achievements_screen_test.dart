import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/views/achievements_screen.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, {Size? size}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size ?? const Size(390, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AchievementsScreen()),
    );
    await tester.pumpAndSettle();
  }

  List<String> shownTitles(WidgetTester tester) {
    final titles = Achievement.all.map((item) => item.title).toSet();
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where(titles.contains)
        .toList();
    return shown;
  }

  testWidgets('groups all 20 by kind, the nearest goal first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);

    expect(shownTitles(tester), [
      // Regularność
      'Dobry początek',
      'Pełna dziesiątka',
      'Żelazny nawyk',
      'Niezłomny',
      'Legenda',
      'Stały bywalec',
      'Sto dni ciekawości',
      // Czytanie
      'Ciekawski',
      'Mól książkowy',
      'Chodząca encyklopedia',
      'Człowiek renesansu',
      'Kolekcjoner',
      // Quizy i pamięć
      'Bezbłędnie',
      'Mistrz quizów',
      'Quizowy weteran',
      'Pamięć słonia',
      'Głowa jak sejf',
      'Powrót do przeszłości',
      'Nic nie umyka',
      // Dzielenie się
      'Podaj dalej',
    ]);
    for (final header in [
      'Regularność',
      'Czytanie',
      'Quizy i pamięć',
      'Dzielenie się',
    ]) {
      expect(find.text(header), findsOneWidget);
    }
  });

  testWidgets('counts unlocked achievements and marks them', (tester) async {
    SharedPreferences.setMockInitialValues({
      'unlockedAchievements': ['streak-5', 'share-1', 'gone-achievement'],
    });
    await pumpScreen(tester);

    expect(find.text('Odblokowane: 2 / 20'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(18));
  });

  testWidgets('the last one can be reached on a small phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester, size: const Size(360, 640));

    await tester.scrollUntilVisible(find.text('Podaj dalej'), 300);

    expect(find.text('Podaj dalej'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
