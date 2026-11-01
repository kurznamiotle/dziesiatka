import 'dart:convert';

import 'package:dziesiatka/services/admin_auth_service.dart';
import 'package:dziesiatka/services/admin_service.dart';
import 'package:dziesiatka/views/admin/admin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _row(
  String id,
  String title, {
  String status = 'published',
  String? note,
}) {
  return {
    'id': id,
    'title': title,
    'category': 'Kosmos',
    'short_text': 'Krótki tekst o $title.',
    'long_text': 'Długi tekst.',
    'source_label': 'NASA',
    'source_url': 'https://nasa.gov',
    'status': status,
    'quiz': {
      'question': 'Pytanie?',
      'options': ['A', 'B', 'C'],
      'correctIndex': 0,
    },
    'review_note': note,
  };
}

void main() {
  late List<http.Request> requests;
  late bool isAdmin;
  late bool acceptsPassword;

  setUp(() {
    requests = [];
    isAdmin = true;
    acceptsPassword = true;
  });

  http.Response respond(http.Request request) {
    requests.add(request);
    final path = request.url.path;
    if (path == '/auth/v1/token') {
      if (!acceptsPassword) return http.Response('{}', 400);
      return http.Response(
        jsonEncode({
          'access_token': 't',
          'refresh_token': 'r',
          'expires_in': 3600,
        }),
        200,
      );
    }
    if (path.endsWith('rpc/is_admin')) {
      return http.Response(jsonEncode(isAdmin), 200);
    }
    if (request.method != 'GET') return http.Response('', 204);

    final offset = request.url.queryParameters['offset'];
    if (offset != '0') return http.Response('[]', 200);
    final rows = switch (path) {
      '/rest/v1/facts' => [
        _row('fact-1', 'Opublikowana'),
        _row('fact-2', 'Szkic', status: 'draft', note: 'Jedno źródło.'),
      ],
      '/rest/v1/categories' => [
        {'name': 'Kosmos'},
      ],
      '/rest/v1/usage_days' => [
        {
          'day': '2026-11-01',
          'install_id': 'a' * 32,
          'cards_completed': 10,
          'deck_finished': true,
          'quiz_correct': 3,
          'quiz_total': 4,
          'bonus_rounds': 1,
          'instructions': 'finished',
          'chose_all_categories': false,
          'notifications_allowed': true,
        },
      ],
      _ => <Map<String, dynamic>>[],
    };
    return http.Response.bytes(utf8.encode(jsonEncode(rows)), 200);
  }

  Future<void> pumpPanel(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);
    final client = MockClient((request) async => respond(request));
    final auth = AdminAuthService(
      url: 'https://example.supabase.co',
      publishableKey: 'klucz',
      client: client,
    );
    await tester.pumpWidget(
      AdminApp(
        authService: auth,
        adminService: AdminService(
          auth,
          url: 'https://example.supabase.co',
          publishableKey: 'klucz',
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'a@example.com');
    await tester.enterText(find.byType(TextField).last, 'haslo');
    await tester.tap(find.text('Zaloguj się'));
    await tester.pumpAndSettle();
  }

  Future<void> openPage(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  testWidgets('a wrong password shows a message', (tester) async {
    acceptsPassword = false;
    await pumpPanel(tester);

    await signIn(tester);

    expect(find.text('Niepoprawny adres e-mail lub hasło.'), findsOneWidget);
  });

  testWidgets('an account outside admins gets no access', (tester) async {
    isAdmin = false;
    await pumpPanel(tester);

    await signIn(tester);

    expect(find.text('To konto nie ma dostępu do panelu.'), findsOneWidget);
    expect(find.text('Pulpit'), findsNothing);
  });

  testWidgets('the dashboard shows statistics and stock', (tester) async {
    await pumpPanel(tester);

    await signIn(tester);

    expect(find.text('Instalacje'), findsOneWidget);
    expect(find.text('Zapas ciekawostek'), findsOneWidget);
    expect(find.text('Instrukcja do końca'), findsOneWidget);
  });

  testWidgets('drafts open first, with their doubts', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);

    await openPage(tester, 'Ciekawostki');

    expect(find.text('Szkic'), findsOneWidget);
    expect(find.text('Jedno źródło.'), findsOneWidget);
    expect(find.text('Opublikowana'), findsNothing);
  });

  testWidgets('selected drafts can be published together', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);
    await openPage(tester, 'Ciekawostki');

    await tester.tap(find.text('Zaznacz widoczne'));
    await tester.pump();
    await tester.tap(find.text('Opublikuj (1)'));
    await tester.pumpAndSettle();

    final patch = requests.lastWhere((request) => request.method == 'PATCH');
    expect(patch.url.queryParameters['id'], 'in.("fact-2")');
    expect((jsonDecode(patch.body) as Map)['status'], 'published');
  });

  testWidgets('a pasted file is checked before anything is saved', (
    tester,
  ) async {
    await pumpPanel(tester);
    await signIn(tester);
    await openPage(tester, 'Import');

    await tester.enterText(
      find.byType(TextField).first,
      jsonEncode([
        {
          'title': 'Nowa ciekawostka',
          'category': 'Kosmos',
          'short_text': 'Zupełnie nowa treść o czymś innym.',
          'long_text': 'Pierwszy.\n\nDrugi.',
          'source_label': 'ESA',
          'source_url': 'https://esa.int',
          'quiz': null,
          'status': 'published',
          'review_note': null,
        },
      ]),
    );
    await tester.tap(find.text('Sprawdź'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Do zapisania: 1'), findsOneWidget);
    expect(requests.where((request) => request.method == 'POST').length, 2);

    await tester.tap(find.text('Zapisz (1)'));
    await tester.pumpAndSettle();

    final insert = requests.lastWhere(
      (request) =>
          request.method == 'POST' && request.url.path == '/rest/v1/facts',
    );
    final saved = (jsonDecode(insert.body) as List).single as Map;
    expect(saved['id'], 'fact-003');
    expect(saved['status'], 'draft');
  });

  testWidgets('an invalid file shows a message', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);
    await openPage(tester, 'Import');

    await tester.enterText(find.byType(TextField).first, 'to nie json');
    await tester.tap(find.text('Sprawdź'));
    await tester.pumpAndSettle();

    expect(find.textContaining('poprawna lista JSON'), findsOneWidget);
  });

  testWidgets('the ranking explains missing data', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);

    await openPage(tester, 'Ranking');

    expect(find.textContaining('Za mało danych'), findsOneWidget);
  });

  testWidgets('signing out returns to the form', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);

    await tester.tap(find.byTooltip('Wyloguj'));
    await tester.pumpAndSettle();

    expect(find.text('Zaloguj się'), findsOneWidget);
  });
}
