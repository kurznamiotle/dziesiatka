import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/share_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/share_card_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeShareService extends ShareService {
  _FakeShareService({this.error});

  final Object? error;
  Uint8List? image;
  String? fileName;
  String? text;
  Rect? origin;

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required String text,
    Rect? origin,
  }) async {
    if (error != null) throw error!;
    image = png;
    this.fileName = fileName;
    this.text = text;
    this.origin = origin;
  }
}

void main() {
  final fact = Fact(
    id: 'seed-001',
    title: 'Dzień dłuższy niż rok',
    category: 'Kosmos',
    shortText: 'Jeden obrót Wenus trwa dłużej niż rok.',
    longText: 'Rozwinięcie',
    source: 'Źródło',
    createdAt: DateTime.utc(2026),
  );

  Future<void> pumpSheet(WidgetTester tester, ShareService service) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ShareCardSheet(fact: fact, shareService: service),
        ),
      ),
    );
  }

  Future<void> tapShare(WidgetTester tester) async {
    await tester.tap(find.text('Udostępnij grafikę'));
    await tester.pump();
    // Capturing an image finishes outside the test's fake time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  testWidgets('previews the fact with the app name', (tester) async {
    await pumpSheet(tester, _FakeShareService());

    expect(find.text(fact.title), findsOneWidget);
    expect(find.text(fact.shortText), findsOneWidget);
    expect(find.text('Dziesiątka'), findsOneWidget);
    expect(find.text('Kosmos'), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(find.text('Dowiedz się więcej'), findsNothing);
  });

  testWidgets('shares a 1080 px wide 4:5 PNG', (tester) async {
    final service = _FakeShareService();
    await pumpSheet(tester, service);

    await tapShare(tester);

    expect(service.image, isNotNull);
    expect(service.image!.sublist(1, 4), 'PNG'.codeUnits);
    expect(service.fileName, 'dziesiatka-seed-001.png');
    expect(service.text, contains(fact.title));
    expect(service.origin, isNotNull);

    final size = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(service.image!);
      final image = (await codec.getNextFrame()).image;
      return Size(image.width.toDouble(), image.height.toDouble());
    });
    expect(size!.width, 1080);
    expect(size.height, closeTo(1350, 1));
  });

  testWidgets('a failure shows a message and allows a retry', (tester) async {
    await pumpSheet(tester, _FakeShareService(error: StateError('brak')));

    await tapShare(tester);

    expect(find.text('Nie udało się udostępnić grafiki.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Udostępnij grafikę'),
        matching: find.bySubtype<FilledButton>(),
      ),
    );
    expect(button.onPressed, isNotNull);
  });
}
