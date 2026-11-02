import 'dart:convert';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/fact_report_service.dart';
import 'package:dziesiatka/views/fact_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fact = Fact(
    id: 'seed-001',
    title: 'Dzień dłuższy niż rok',
    category: 'Kosmos',
    shortText: 'Jeden obrót Wenus trwa dłużej niż rok.',
    longText: 'Rozwinięcie',
    sourceLabel: 'Źródło',
    createdAt: DateTime.utc(2026),
  );

  late List<http.Request> requests;
  late int statusCode;

  setUp(() {
    requests = [];
    statusCode = 204;
  });

  Future<void> openReport(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FactDetailsSheet(
            fact: fact,
            reportService: FactReportService(
              url: 'https://example.supabase.co',
              publishableKey: 'klucz',
              client: MockClient((request) async {
                requests.add(request);
                return http.Response('', statusCode);
              }),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Zgłoś błąd'));
    await tester.pumpAndSettle();
  }

  testWidgets('a report is sent with its reason and comment', (tester) async {
    await openReport(tester);

    await tester.tap(find.text('Literówka lub błąd językowy'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Zły przypadek.');
    await tester.tap(find.text('Wyślij'));
    await tester.pumpAndSettle();

    expect(jsonDecode(requests.single.body), {
      'p_fact_id': 'seed-001',
      'p_reason': 'language',
      'p_comment': 'Zły przypadek.',
    });
    expect(find.text('Dziękujemy!'), findsOneWidget);
  });

  testWidgets('a failed report can be sent again', (tester) async {
    statusCode = 500;
    await openReport(tester);

    await tester.tap(find.text('Wyślij'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nie udało się wysłać. Spróbuj ponownie.'),
      findsOneWidget,
    );

    statusCode = 204;
    await tester.tap(find.text('Wyślij'));
    await tester.pumpAndSettle();

    expect(requests, hasLength(2));
    expect(find.text('Dziękujemy!'), findsOneWidget);
  });

  testWidgets('cancelling sends nothing', (tester) async {
    await openReport(tester);

    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
    expect(find.text('Wyślij'), findsNothing);
  });
}
