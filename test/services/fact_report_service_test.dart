import 'dart:convert';

import 'package:dziesiatka/models/fact_report.dart';
import 'package:dziesiatka/services/fact_report_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  FactReportService serviceWith(
    Future<http.Response> Function(http.Request request) answer,
  ) {
    return FactReportService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      client: MockClient(answer),
    );
  }

  test('a report goes to the database function', () async {
    late http.Request sent;
    final service = serviceWith((request) async {
      sent = request;
      return http.Response('', 204);
    });

    final isSent = await service.send(
      'seed-001',
      FactReportReason.wrongFact,
      '  Zła data.  ',
    );

    expect(isSent, isTrue);
    expect(sent.url.path, '/rest/v1/rpc/report_fact');
    expect(sent.headers['apikey'], 'klucz');
    expect(jsonDecode(sent.body), {
      'p_fact_id': 'seed-001',
      'p_reason': 'wrong_fact',
      'p_comment': 'Zła data.',
    });
  });

  test('a rejected report answers no', () async {
    final service = serviceWith((_) async => http.Response('', 404));

    expect(await service.send('seed-001', FactReportReason.other, ''), isFalse);
  });

  test('a connection failure answers no', () async {
    final service = serviceWith((_) async => throw http.ClientException('x'));

    expect(await service.send('seed-001', FactReportReason.other, ''), isFalse);
  });
}
