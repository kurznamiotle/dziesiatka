import 'dart:convert';

import 'package:dziesiatka/services/supabase_fact_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, dynamic> row(int number, {String status = 'published'}) {
    return {
      'id': 'fact-$number',
      'title': 'Żółty tytuł $number',
      'category': 'Kosmos',
      'short_text': 'Zajawka',
      'long_text': 'Rozwinięcie',
      'source_label': 'NASA',
      'source_url': 'https://nasa.gov',
      'quiz': {
        'question': 'Pytanie',
        'options': ['A', 'B', 'C'],
        'correctIndex': 1,
      },
      'status': status,
      'created_at': '2026-01-01T00:00:00+00:00',
      'updated_at': '2026-02-01T12:00:00.123456+00:00',
    };
  }

  http.Response json(Object body, {int status = 200}) {
    return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
  }

  SupabaseFactSource source(MockClientHandler handler) {
    return SupabaseFactSource(
      url: 'https://abc.supabase.co',
      publishableKey: 'sb_publishable_test',
      client: MockClient(handler),
    );
  }

  test('reads a row, keeping Polish letters', () async {
    final facts = await source((_) async => json([row(1)])).loadFacts();

    final fact = facts.single;
    expect(fact.id, 'fact-1');
    expect(fact.title, 'Żółty tytuł 1');
    expect(fact.shortText, 'Zajawka');
    expect(fact.sourceLabel, 'NASA');
    expect(fact.sourceUrl, 'https://nasa.gov');
    expect(fact.quiz!.correctIndex, 1);
    expect(fact.isWithdrawn, isFalse);
    expect(fact.updatedAt.isAfter(fact.createdAt), isTrue);
  });

  test('recognizes a withdrawn fact', () async {
    final facts = await source(
      (_) async => json([row(1, status: 'withdrawn')]),
    ).loadFacts();

    expect(facts.single.isWithdrawn, isTrue);
  });

  test('sends the key only in the apikey header', () async {
    late http.Request sent;
    await source((request) async {
      sent = request;
      return json([]);
    }).loadFacts();

    expect(sent.headers['apikey'], 'sb_publishable_test');
    expect(sent.headers.containsKey('Authorization'), isFalse);
    expect(sent.url.path, '/rest/v1/facts');
  });

  test('asks only for rows changed since the given time', () async {
    late Uri url;
    await source((request) async {
      url = request.url;
      return json([]);
    }).loadFacts(changedSince: DateTime.utc(2026, 2, 1, 12));

    expect(url.queryParameters['updated_at'], 'gte.2026-02-01T12:00:00.000Z');
  });

  test('asks for everything without a time', () async {
    late Uri url;
    await source((request) async {
      url = request.url;
      return json([]);
    }).loadFacts();

    expect(url.queryParameters.containsKey('updated_at'), isFalse);
  });

  test('downloads all pages', () async {
    final offsets = <String>[];
    final facts = await source((request) async {
      final offset = request.url.queryParameters['offset']!;
      offsets.add(offset);
      final count = offset == '0' ? 500 : 3;
      return json([for (var i = 0; i < count; i++) row(i)]);
    }).loadFacts();

    expect(facts, hasLength(503));
    expect(offsets, ['0', '500']);
  });

  test('a server error throws', () async {
    await expectLater(
      source((_) async => json({'message': 'brak'}, status: 401)).loadFacts(),
      throwsStateError,
    );
  });
}
