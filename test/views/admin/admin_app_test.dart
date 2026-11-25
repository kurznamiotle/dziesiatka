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
  Map<String, dynamic>? offer,
  String kind = 'regular',
}) {
  return {
    'id': id,
    'title': title,
    'kind': kind,
    'category': kind == 'partner' ? 'Ciekawostka partnerska' : 'Kosmos',
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
    'offer': offer,
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
        _row(
          'fact-3',
          'Z poleceniem',
          offer: {
            'product': 'Atlas nieba',
            'shop': 'Księgarnia',
            'url': 'https://example.com/atlas',
          },
        ),
        _row(
          'fact-4',
          'Po terminie',
          offer: {
            'product': 'Stary atlas',
            'shop': 'Księgarnia',
            'url': 'https://example.com/stary',
            'until': '2020-01-01',
          },
        ),
        _row(
          'partner-001',
          'Książka o Wenus',
          kind: 'partner',
          offer: {
            'product': 'Wenus z bliska',
            'shop': 'Księgarnia',
            'url': 'https://example.com/wenus',
            'until': '2099-12-31',
          },
        ),
      ],
      '/rest/v1/categories' => [
        {'name': 'Ciekawostka partnerska'},
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
      '/rest/v1/fact_reports' => [
        {
          'id': 5,
          'fact_id': 'fact-1',
          'reason': 'wrong_fact',
          'comment': 'Zła data.',
          'created_at': '2026-11-02T10:00:00+00:00',
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

  testWidgets('a handled report is removed', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);

    await openPage(tester, 'Zgłoszenia');

    expect(find.text('Opublikowana'), findsOneWidget);
    expect(find.textContaining('Nieprawdziwa informacja'), findsOneWidget);
    expect(find.textContaining('Zła data.'), findsOneWidget);

    await tester.tap(find.text('Załatwione'));
    await tester.pumpAndSettle();

    final removal = requests.singleWhere(
      (request) => request.method == 'DELETE',
    );
    expect(removal.url.path, '/rest/v1/fact_reports');
    expect(removal.url.queryParameters['id'], 'eq.5');
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
    expect(saved['id'], 'fact-005');
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

  testWidgets('facts with offers can be filtered and are marked', (
    tester,
  ) async {
    await pumpPanel(tester);
    await signIn(tester);
    await openPage(tester, 'Ciekawostki');

    await tester.tap(find.text('Z poleceniem'));
    await tester.pumpAndSettle();

    expect(find.text('Szkic'), findsNothing);
    expect(find.text('Polecenie: Atlas nieba · Księgarnia'), findsOneWidget);
    expect(
      find.text('Polecenie wygasło 2020-01-01: Stary atlas'),
      findsOneWidget,
    );
  });

  testWidgets('an offer is edited and removed in the form', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);
    await openPage(tester, 'Ciekawostki');
    await tester.tap(find.text('Z poleceniem'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Działania').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();

    expect(find.text('Polecenie partnerskie'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Link (https)'),
      'http://example.com',
    );
    await tester.ensureVisible(find.text('Zapisz'));
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(find.textContaining('https://'), findsWidgets);
    expect(requests.where((request) => request.method == 'PATCH'), isEmpty);

    await tester.ensureVisible(find.text('Usuń polecenie'));
    await tester.tap(find.text('Usuń polecenie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    final patch = requests.lastWhere((request) => request.method == 'PATCH');
    final body = jsonDecode(patch.body) as Map<String, dynamic>;
    expect(body.containsKey('offer'), isTrue);
    expect(body['offer'], isNull);
  });

  testWidgets('a CSV file sets offers of existing facts', (tester) async {
    await pumpPanel(tester);
    await signIn(tester);
    await openPage(tester, 'Import');

    await tester.enterText(
      find.byType(TextField).first,
      'id,title,offer_product,offer_shop,offer_url,offer_until\n'
      'fact-1,Opublikowana,Mapa,Sklep,https://example.com/mapa,2026-12-31\n'
      'fact-2,Szkic,,,,\n',
    );
    await tester.tap(find.text('Sprawdź'));
    await tester.pumpAndSettle();

    expect(find.text('Zapisz polecenia (1)'), findsOneWidget);
    await tester.tap(find.text('Zapisz polecenia (1)'));
    await tester.pumpAndSettle();

    final patches = requests.where((request) => request.method == 'PATCH');
    expect(patches, hasLength(1));
    expect(patches.single.url.queryParameters['id'], 'eq.fact-1');
    expect(jsonDecode(patches.single.body), {
      'offer': {
        'product': 'Mapa',
        'shop': 'Sklep',
        'url': 'https://example.com/mapa',
        'until': '2026-12-31',
      },
    });
  });

  group('offers page', () {
    Future<void> openOffers(WidgetTester tester) async {
      await pumpPanel(tester);
      await signIn(tester);
      await openPage(tester, 'Polecenia');
    }

    Map<String, dynamic> lastBody(String method) {
      final request = requests.lastWhere((item) => item.method == method);
      return jsonDecode(request.body) is List
          ? (jsonDecode(request.body) as List).single as Map<String, dynamic>
          : jsonDecode(request.body) as Map<String, dynamic>;
    }

    testWidgets('lists partner and regular offers with counts', (tester) async {
      await openOffers(tester);

      expect(find.text('Książka o Wenus'), findsOneWidget);
      expect(find.text('Z poleceniem'), findsOneWidget);
      expect(find.text('Po terminie'), findsOneWidget);
      expect(find.text('Opublikowana'), findsNothing);
      expect(find.text('partnerska'), findsOneWidget);
      expect(find.text('zwykła'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('wygasłe'),
        ),
        findsOneWidget,
      );
      expect(find.text('Kliknięcia łącznie'), findsOneWidget);
      // fact_stats is empty in this test, so the column is unknown.
      expect(find.text('brak danych'), findsWidgets);
    });

    testWidgets('filters by kind', (tester) async {
      await openOffers(tester);

      await tester.tap(find.text('Wszystkie rodzaje').hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ciekawostki partnerskie').hitTestable().last);
      await tester.pumpAndSettle();

      expect(find.text('Książka o Wenus'), findsOneWidget);
      expect(find.text('Z poleceniem'), findsNothing);
    });

    testWidgets('a partner fact stays off the fact list', (tester) async {
      await pumpPanel(tester);
      await signIn(tester);
      await openPage(tester, 'Ciekawostki');
      await tester.tap(find.text('Z poleceniem'));
      await tester.pumpAndSettle();

      expect(find.text('Książka o Wenus'), findsNothing);
      expect(find.text('Ciekawostka partnerska'), findsNothing);
    });

    testWidgets('a new partner fact is previewed and saved', (tester) async {
      await openOffers(tester);

      await tester.tap(find.text('Nowa ciekawostka partnerska'));
      await tester.pumpAndSettle();
      expect(find.text('Pytanie quizowe'), findsNothing);
      expect(find.text('Kategoria'), findsNothing);

      Future<void> type(String label, String text) async {
        await tester.enterText(find.widgetWithText(TextField, label), text);
        await tester.pump();
      }

      await type('Tytuł', 'Doba na Wenus');
      await type('Krótki tekst', 'Doba trwa dłużej niż rok.');
      await type('Długi tekst', 'Wenus obraca się bardzo wolno.');
      await type('Źródło faktu', 'NASA');
      await type('Produkt', 'Atlas nieba');
      await type('Sklep', 'Księgarnia');
      await type('Link (https)', 'https://example.com/atlas');
      await type('Ważne do (opcjonalnie)', '2099-01-31');

      expect(find.text('Ciekawostka partnerska'), findsOneWidget);
      expect(find.text('Atlas nieba · Księgarnia ›'), findsOneWidget);

      await tester.tap(find.text('Zapisz i opublikuj'));
      await tester.pumpAndSettle();

      final body = lastBody('POST');
      expect(body['id'], 'partner-002');
      expect(body['kind'], 'partner');
      expect(body['category'], 'Ciekawostka partnerska');
      expect(body['status'], 'published');
      expect(body['quiz'], isNull);
      expect(body['offer'], {
        'product': 'Atlas nieba',
        'shop': 'Księgarnia',
        'url': 'https://example.com/atlas',
        'until': '2099-01-31',
      });
    });

    testWidgets('a partner fact without a product is not saved', (
      tester,
    ) async {
      await openOffers(tester);
      await tester.tap(find.text('Nowa ciekawostka partnerska'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zapisz i opublikuj'));
      await tester.pumpAndSettle();

      expect(find.text('Podaj produkt, sklep i link.'), findsOneWidget);
      expect(
        requests
            .where((request) => request.url.path == '/rest/v1/facts')
            .where((request) => request.method == 'POST'),
        isEmpty,
      );
    });

    testWidgets('+30 days moves the end date', (tester) async {
      await openOffers(tester);

      await tester.tap(find.byTooltip('Działania').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('+30 dni'));
      await tester.pumpAndSettle();

      final patch = requests.lastWhere((request) => request.method == 'PATCH');
      expect(patch.url.queryParameters['id'], 'eq.partner-001');
      expect(lastBody('PATCH')['offer']['until'], '2100-01-30');
    });

    testWidgets('deleting a partner fact withdraws it after asking', (
      tester,
    ) async {
      await openOffers(tester);

      await tester.tap(find.byTooltip('Działania').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      expect(find.text('Usunąć polecenie?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
      await tester.pumpAndSettle();

      expect(lastBody('PATCH'), {'status': 'withdrawn'});
    });

    testWidgets('deleting a regular offer keeps the fact', (tester) async {
      await openOffers(tester);

      await tester.tap(find.byTooltip('Działania').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(requests.where((request) => request.method == 'PATCH'), isEmpty);

      await tester.tap(find.byTooltip('Działania').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Usuń'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Usuń'));
      await tester.pumpAndSettle();

      expect(lastBody('PATCH'), {'offer': null});
    });

    testWidgets('an offer is added to an existing fact', (tester) async {
      await openOffers(tester);

      await tester.tap(find.text('Dodaj polecenie do istniejącej ciekawostki'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'opubl');
      await tester.pumpAndSettle();
      expect(find.text('Szkic'), findsNothing);
      await tester.tap(find.text('Opublikowana'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Produkt'), 'Mapa');
      await tester.enterText(find.widgetWithText(TextField, 'Sklep'), 'Sklep');
      await tester.enterText(
        find.widgetWithText(TextField, 'Link (https)'),
        'https://example.com/mapa',
      );
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      final patch = requests.lastWhere((request) => request.method == 'PATCH');
      expect(patch.url.queryParameters['id'], 'eq.fact-1');
      expect(lastBody('PATCH'), {
        'offer': {
          'product': 'Mapa',
          'shop': 'Sklep',
          'url': 'https://example.com/mapa',
        },
      });
    });
  });
}
