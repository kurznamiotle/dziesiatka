import 'dart:convert';

import 'package:dziesiatka/main.dart';
import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/daily_deck_service.dart';
import 'package:dziesiatka/services/theme_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/keep_order_random.dart';

class _FakeAppInfoService extends AppInfoService {
  const _FakeAppInfoService();

  @override
  Future<String> getVersion() async => '1.2.3';
}

void main() {
  late List<http.Request> requests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.clear();
    requests = [];
  });

  Map<String, dynamic> lastReport() {
    final request = requests.lastWhere(
      (request) => request.url.path.endsWith('record_usage_day'),
    );
    return (jsonDecode(request.body) as Map<String, dynamic>)['p_report']
        as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> factStats() {
    return [
      for (final request in requests)
        if (request.url.path.endsWith('record_fact_stats'))
          ...((jsonDecode(request.body) as Map<String, dynamic>)['p_stats']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>(),
    ];
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      DziesiatkaApp(
        themeService: ThemeService(),
        random: const KeepOrderRandom(),
        usageService: UsageService(
          url: 'https://example.supabase.co',
          publishableKey: 'klucz',
          appInfoService: const _FakeAppInfoService(),
          client: MockClient((request) async {
            requests.add(request);
            return http.Response('', 204);
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a whole day reaches the statistics', (tester) async {
    await pumpApp(tester);
    expect(lastReport()['cards_completed'], 0);

    await tester.tap(find.text('Dowiedz się więcej').last);
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Polub'));
    await tester.pumpAndSettle();
    for (var i = 0; i < DailyDeckService.deckSize - 1; i++) {
      await tester.tap(find.text('Dalej'));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < DailyDeckService.quizQuestionCount; i++) {
      await tester.tap(find.textContaining(RegExp(r'^A\. ')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    final report = lastReport();
    expect(report['cards_completed'], DailyDeckService.deckSize);
    expect(report['deck_finished'], isTrue);
    expect(report['quiz_total'], DailyDeckService.quizQuestionCount);
    expect(report['streak_bucket'], '1-4');

    int total(String key) {
      return factStats().fold(0, (sum, fact) => sum + (fact[key] as int));
    }

    expect(total('shown'), DailyDeckService.deckSize);
    expect(total('liked'), 1);
    expect(total('opened'), 1);
    expect(
      total('quiz_correct') + total('quiz_wrong'),
      DailyDeckService.quizQuestionCount,
    );
  });

  testWidgets('a bonus round is counted', (tester) async {
    await pumpApp(tester);
    for (var i = 0; i < DailyDeckService.deckSize; i++) {
      await tester.tap(find.text('Dalej'));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < DailyDeckService.quizQuestionCount; i++) {
      await tester.tap(find.textContaining(RegExp(r'^A\. ')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Jeszcze 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    expect(lastReport()['bonus_rounds'], 1);
    expect(lastReport()['cards_completed'], DailyDeckService.deckSize + 1);
  });
}
