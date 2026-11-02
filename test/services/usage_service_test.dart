import 'dart:convert';

import 'package:dziesiatka/services/app_info_service.dart';
import 'package:dziesiatka/services/usage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppInfoService extends AppInfoService {
  const _FakeAppInfoService();

  @override
  Future<String> getVersion() async => '1.2.3';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;
  late int statusCode;
  late DateTime now;
  late UsageService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    statusCode = 204;
    now = DateTime(2026, 11, 2, 9);
    service = UsageService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      appInfoService: const _FakeAppInfoService(),
      now: () => now,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', statusCode);
      }),
    );
  });

  List<Map<String, dynamic>> reports() {
    return [
      for (final request in requests)
        if (request.url.path.endsWith('record_usage_day'))
          (jsonDecode(request.body) as Map<String, dynamic>)['p_report']
              as Map<String, dynamic>,
    ];
  }

  List<dynamic> factStats() {
    return [
      for (final request in requests)
        if (request.url.path.endsWith('record_fact_stats'))
          ...(jsonDecode(request.body) as Map<String, dynamic>)['p_stats']
              as List<dynamic>,
    ];
  }

  test('a start reports the day with its anonymous id', () async {
    await service.recordToday();

    expect(requests.single.url.path, '/rest/v1/rpc/record_usage_day');
    expect(requests.single.headers['apikey'], 'klucz');
    final report = reports().single;
    expect(report['install_id'], matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(report['day'], '2026-11-02');
    expect(report['app_version'], '1.2.3');
    expect(report['cards_completed'], 0);
  });

  test('an unchanged day is sent only once', () async {
    await service.recordToday();
    await service.recordToday();

    expect(reports(), hasLength(1));
  });

  test('a finished day is sent at once with its totals', () async {
    await service.cardCompleted('a', liked: true);
    await service.cardCompleted('b', liked: false);
    await service.bonusRoundStarted();

    await service.dayFinished(streak: 7, quizCorrect: 3, quizTotal: 4);

    final report = reports().single;
    expect(report['cards_completed'], 2);
    expect(report['deck_finished'], isTrue);
    expect(report['quiz_correct'], 3);
    expect(report['quiz_total'], 4);
    expect(report['bonus_rounds'], 1);
    expect(report['streak_bucket'], '5-9');
  });

  test('more cards after finishing update the same day', () async {
    await service.dayFinished(streak: 1, quizCorrect: 4, quizTotal: 4);
    await service.cardCompleted('a', liked: false);

    await service.recordToday();

    expect(reports().last['cards_completed'], 1);
    expect(reports().last['deck_finished'], isTrue);
  });

  test('a day left unsent arrives on the next start', () async {
    await service.cardCompleted('a', liked: false);

    now = now.add(const Duration(days: 1));
    await service.recordToday();

    expect(reports().map((report) => report['day']), {
      '2026-11-02',
      '2026-11-03',
    });
    expect(reports().first['install_id'], reports().last['install_id']);
  });

  test('first-run choices are reported', () async {
    await service.instructionsLeft(skipped: true);
    await service.categoriesChosen(choseAll: false);
    await service.notificationsAnswered(isAllowed: true);

    await service.recordToday();

    final report = reports().single;
    expect(report['instructions'], 'skipped');
    expect(report['chose_all_categories'], isFalse);
    expect(report['notifications_allowed'], isTrue);
  });

  test('settings choices are reported', () async {
    await service.categoriesChanged();
    await service.remindersState(isEnabled: false);

    await service.recordToday();

    expect(reports().single['categories_changed'], isTrue);
    expect(reports().single['reminders_enabled'], isFalse);
  });

  test('fact results add up without any installation id', () async {
    await service.cardCompleted('a', liked: true);
    await service.cardCompleted('a', liked: false);
    await service.factOpened('a');
    await service.factShared('a');
    await service.quizAnswered('a', isCorrect: true);
    await service.quizAnswered('b', isCorrect: false);

    await service.recordToday();

    expect(factStats(), hasLength(2));
    final first = factStats().first as Map<String, dynamic>;
    expect(first.keys, {
      'id',
      'shown',
      'liked',
      'opened',
      'shared',
      'quiz_correct',
      'quiz_wrong',
    });
    expect(first['shown'], 2);
    expect(first['liked'], 1);
    expect(first['opened'], 1);
    expect(first['shared'], 1);
    expect(first['quiz_correct'], 1);
    expect((factStats().last as Map<String, dynamic>)['quiz_wrong'], 1);
  });

  test('fact results are sent only once', () async {
    await service.factOpened('a');
    await service.recordToday();
    await service.recordToday();

    expect(factStats(), hasLength(1));
  });

  test('rejected numbers wait for the next start', () async {
    await service.factOpened('a');
    statusCode = 404;
    await service.recordToday();

    statusCode = 204;
    await service.recordToday();

    await service.recordToday();

    expect(reports(), hasLength(2));
    expect(factStats(), hasLength(2));
  });

  test('quick events do not overwrite each other', () async {
    await Future.wait([
      for (var i = 0; i < 5; i++) service.cardCompleted('a', liked: false),
    ]);

    await service.recordToday();

    expect(reports().single['cards_completed'], 5);
  });

  test('a connection failure stays silent', () async {
    final offline = UsageService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      appInfoService: const _FakeAppInfoService(),
      client: MockClient((_) => throw http.ClientException('brak sieci')),
    );

    await expectLater(offline.recordToday(), completes);
  });

  group('when consent is needed', () {
    UsageService askingService() {
      return UsageService(
        url: 'https://example.supabase.co',
        publishableKey: 'klucz',
        appInfoService: const _FakeAppInfoService(),
        now: () => now,
        asksForConsent: true,
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('', statusCode);
        }),
      );
    }

    test('nothing is stored or sent before the answer', () async {
      final service = askingService();

      await service.cardCompleted('a', liked: true);
      await service.recordToday();

      expect(await service.needsConsent(), isTrue);
      expect(await service.isEnabled(), isFalse);
      expect(requests, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('agreeing keeps what happened before the answer', () async {
      final service = askingService();
      await service.instructionsLeft(skipped: true);

      await service.setEnabled(true);
      await service.recordToday();

      expect(await service.needsConsent(), isFalse);
      expect(reports().single['instructions'], 'skipped');
    });

    test('refusing forgets what happened before the answer', () async {
      final service = askingService();
      await service.cardCompleted('a', liked: true);

      await service.setEnabled(false);
      await service.recordToday();

      expect(await service.needsConsent(), isFalse);
      expect(requests, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'usageStatsEnabled'});
    });

    test('the answer survives a restart', () async {
      await askingService().setEnabled(true);

      final restarted = askingService();

      expect(await restarted.needsConsent(), isFalse);
      expect(await restarted.isEnabled(), isTrue);
    });
  });

  test('without the question nothing changes', () async {
    expect(await service.needsConsent(), isFalse);
    expect(await service.isEnabled(), isTrue);
  });

  test('turned off records and sends nothing', () async {
    await service.setEnabled(false);

    await service.cardCompleted('a', liked: true);
    await service.recordToday();

    expect(requests, isEmpty);
  });

  test('turning off forgets the id and unsent numbers', () async {
    await service.recordToday();
    final firstId = reports().single['install_id'];
    await service.factOpened('a');

    await service.setEnabled(false);
    await service.setEnabled(true);
    now = now.add(const Duration(days: 1));
    await service.recordToday();

    expect(reports().last['install_id'], isNot(firstId));
    expect(factStats(), isEmpty);
  });
}
