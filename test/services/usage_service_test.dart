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

  UsageService newService() {
    return UsageService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      appInfoService: const _FakeAppInfoService(),
      now: () => now,
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('', statusCode);
      }),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    statusCode = 204;
    now = DateTime(2026, 11, 2, 9);
    service = newService();
  });

  Map<String, dynamic> sentBody(int index) {
    return jsonDecode(requests[index].body) as Map<String, dynamic>;
  }

  test('sends only a random id, the platform and the version', () async {
    await service.recordToday();

    expect(requests.single.url.path, '/rest/v1/rpc/record_usage');
    expect(requests.single.headers['apikey'], 'klucz');
    final body = sentBody(0);
    expect(body.keys, {'p_install_id', 'p_platform', 'p_app_version'});
    expect(body['p_install_id'], matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(body['p_app_version'], '1.2.3');
  });

  test('sends once a day and keeps the id on the next day', () async {
    await service.recordToday();
    await service.recordToday();
    expect(requests, hasLength(1));

    now = now.add(const Duration(days: 1));
    await service.recordToday();

    expect(requests, hasLength(2));
    expect(sentBody(1)['p_install_id'], sentBody(0)['p_install_id']);
  });

  test('a rejected note is sent again on the next start', () async {
    statusCode = 404;
    await service.recordToday();

    statusCode = 204;
    await service.recordToday();

    expect(requests, hasLength(2));
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

  test('turned off sends nothing', () async {
    await service.setEnabled(false);

    await service.recordToday();

    expect(requests, isEmpty);
  });

  test('turning off forgets the id', () async {
    await service.recordToday();
    await service.setEnabled(false);
    await service.setEnabled(true);

    now = now.add(const Duration(days: 1));
    await service.recordToday();

    expect(sentBody(1)['p_install_id'], isNot(sentBody(0)['p_install_id']));
  });
}
