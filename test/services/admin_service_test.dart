import 'dart:convert';

import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/services/admin_auth_service.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<http.Request> requests;
  late DateTime now;
  late String nextToken;
  late http.Response Function(http.Request request) answer;

  setUp(() {
    requests = [];
    now = DateTime(2026, 11, 2, 12);
    nextToken = 'token-1';
    answer = (_) => http.Response('[]', 200);
  });

  http.Client client() {
    return MockClient((request) async {
      requests.add(request);
      if (request.url.path == '/auth/v1/token') {
        if (nextToken.isEmpty) return http.Response('{}', 400);
        return http.Response(
          jsonEncode({
            'access_token': nextToken,
            'refresh_token': 'odswiez',
            'expires_in': 3600,
          }),
          200,
        );
      }
      return answer(request);
    });
  }

  AdminAuthService newAuth() {
    return AdminAuthService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      client: client(),
      now: () => now,
    );
  }

  Future<AdminService> signedIn() async {
    final auth = newAuth();
    await auth.signIn('a@example.com', 'haslo');
    return AdminService(
      auth,
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      client: client(),
    );
  }

  group('signing in', () {
    test('a wrong password is refused', () async {
      nextToken = '';
      final auth = newAuth();

      expect(await auth.signIn('a@example.com', 'zle'), isFalse);
      expect(auth.isSignedIn, isFalse);
    });

    test('a token close to its end is renewed', () async {
      final auth = newAuth();
      await auth.signIn('a@example.com', 'haslo');
      nextToken = 'token-2';

      expect(await auth.accessToken(), 'token-1');

      now = now.add(const Duration(minutes: 59, seconds: 30));

      expect(await auth.accessToken(), 'token-2');
      expect(requests.last.url.query, 'grant_type=refresh_token');
    });

    test('a session that cannot be renewed ends', () async {
      final auth = newAuth();
      await auth.signIn('a@example.com', 'haslo');
      nextToken = '';
      now = now.add(const Duration(hours: 2));

      await expectLater(auth.accessToken(), throwsStateError);
      expect(auth.isSignedIn, isFalse);
    });

    test('before signing in there is no token', () {
      expect(newAuth().accessToken(), throwsStateError);
    });
  });

  group('data', () {
    AdminFact fact(String id) {
      return AdminFact(
        id: id,
        title: 'Tytuł',
        category: 'Kosmos',
        shortText: 'Krótki',
        longText: 'Długi',
        sourceLabel: 'NASA',
        status: AdminFact.draft,
      );
    }

    test('requests go out as the signed-in user', () async {
      final service = await signedIn();

      await service.loadCategories();

      expect(requests.last.headers['apikey'], 'klucz');
      expect(requests.last.headers['Authorization'], 'Bearer token-1');
    });

    test('the admin check reads the answer of the database', () async {
      final service = await signedIn();
      answer = (_) => http.Response('true', 200);
      expect(await service.isAdmin(), isTrue);

      answer = (_) => http.Response('false', 200);
      expect(await service.isAdmin(), isFalse);
    });

    test('all pages of a long table are loaded', () async {
      final service = await signedIn();
      answer = (request) {
        final offset = int.parse(request.url.queryParameters['offset']!);
        final count = offset == 0 ? 1000 : 2;
        final rows = [
          for (var i = 0; i < count; i++) {'name': 'k$offset-$i'},
        ];
        return http.Response.bytes(utf8.encode(jsonEncode(rows)), 200);
      };

      expect(await service.loadCategories(), hasLength(1002));
    });

    test('new facts are sent together', () async {
      final service = await signedIn();
      answer = (_) => http.Response('', 201);

      await service.insertFacts([fact('fact-1'), fact('fact-2')]);

      final sent = jsonDecode(requests.last.body) as List<dynamic>;
      expect(requests.last.url.path, '/rest/v1/facts');
      expect(sent, hasLength(2));
    });

    test('publishing several clears their notes', () async {
      final service = await signedIn();
      answer = (_) => http.Response('', 204);

      await service.setStatus(['fact-1', 'fact-2'], AdminFact.published);

      expect(requests.last.url.queryParameters['id'], 'in.("fact-1","fact-2")');
      expect(jsonDecode(requests.last.body), {
        'status': 'published',
        'review_note': null,
      });
    });

    test('rejecting keeps the note', () async {
      final service = await signedIn();
      answer = (_) => http.Response('', 204);

      await service.setStatus(['fact-1'], AdminFact.rejected);

      expect(jsonDecode(requests.last.body), {'status': 'rejected'});
    });

    test('a refused change raises an error', () async {
      final service = await signedIn();
      answer = (_) => http.Response('', 403);

      await expectLater(service.updateFact(fact('fact-1')), throwsStateError);
    });
  });
}
