import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/share_service.dart';
import 'package:dziesiatka/views/app_theme.dart';
import 'package:dziesiatka/views/category_badge.dart';
import 'package:dziesiatka/views/share_card_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeShareService extends ShareService {
  _FakeShareService({this.error});

  final Object? error;
  Uint8List? image;
  Uint8List? savedImage;
  String? fileName;
  String? title;
  Rect? origin;

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required String title,
    Rect? origin,
  }) async {
    if (error != null) throw error!;
    image = png;
    this.fileName = fileName;
    this.title = title;
    this.origin = origin;
  }

  @override
  Future<void> saveImage(Uint8List png, {required String fileName}) async {
    if (error != null) throw error!;
    savedImage = png;
    this.fileName = fileName;
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

  Future<void> tapAndCapture(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    // Capturing an image finishes outside the test's fake time.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  }

  Future<void> tapShare(WidgetTester tester) =>
      tapAndCapture(tester, 'Udostępnij grafikę');

  Future<void> tapSave(WidgetTester tester) =>
      tapAndCapture(tester, 'Zapisz w galerii');

  testWidgets('saves the image and confirms it', (tester) async {
    final service = _FakeShareService();
    await pumpSheet(tester, service);

    await tapSave(tester);

    expect(service.savedImage!.sublist(1, 4), 'PNG'.codeUnits);
    expect(service.fileName, 'dziesiatka-story.png');
    expect(service.image, isNull);
    expect(find.text('Zapisano w galerii.'), findsOneWidget);
  });

  testWidgets('a refused gallery shows a message', (tester) async {
    await pumpSheet(tester, _FakeShareService(error: StateError('brak')));

    await tapSave(tester);

    expect(find.text('Nie udało się zapisać grafiki.'), findsOneWidget);
    expect(find.text('Zapisano w galerii.'), findsNothing);
  });

  testWidgets('sharing again clears an earlier message', (tester) async {
    final service = _FakeShareService();
    await pumpSheet(tester, service);
    await tapSave(tester);

    await tapShare(tester);

    expect(find.text('Zapisano w galerii.'), findsNothing);
  });

  testWidgets('offers both ways to use the image', (tester) async {
    await pumpSheet(tester, _FakeShareService());

    expect(find.text('Udostępnij grafikę'), findsOneWidget);
    expect(find.text('Zapisz w galerii'), findsOneWidget);
  });

  testWidgets('previews the fact with the app name', (tester) async {
    await pumpSheet(tester, _FakeShareService());

    expect(find.text(fact.title), findsOneWidget);
    expect(find.text(fact.shortText), findsOneWidget);
    expect(find.text('Dziesiątka'), findsOneWidget);
    expect(find.text('Kosmos'), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(find.text('Dowiedz się więcej'), findsNothing);
  });

  testWidgets('shares a 1080 x 1920 px PNG', (tester) async {
    final service = _FakeShareService();
    await pumpSheet(tester, service);

    await tapShare(tester);

    expect(service.image, isNotNull);
    expect(service.image!.sublist(1, 4), 'PNG'.codeUnits);
    expect(service.fileName, 'dziesiatka-story.png');
    expect(service.title, 'Dziesiątka - Ciekawostka na dziś');
    expect(service.origin, isNotNull);

    final size = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(service.image!);
      final image = (await codec.getNextFrame()).image;
      return Size(image.width.toDouble(), image.height.toDouble());
    });
    expect(size, const Size(1080, 1920));
  });

  testWidgets('keeps the card centered and out of the safe zones', (
    tester,
  ) async {
    await pumpSheet(tester, _FakeShareService());

    final image = tester.getRect(find.byType(FittedBox));
    double position(double y) => (y - image.top) / image.height * 1920;

    final top = position(tester.getRect(find.byType(CategoryBadge)).top);
    final bottom = position(tester.getRect(find.text(fact.shortText)).bottom);
    final brand = position(tester.getRect(find.text('Dziesiątka')).bottom);

    expect(image.width / image.height, closeTo(9 / 16, 0.001));
    expect((top + bottom) / 2, closeTo(960, 1));
    expect(top, greaterThan(250));
    expect(bottom, lessThan(1920 - 340));
    expect(brand, closeTo(1920 - 342, 3));
  });

  testWidgets('the longest text fits and the dark theme changes nothing', (
    tester,
  ) async {
    final longFact = Fact(
      id: 'seed-002',
      title: 'Bardzo długi tytuł ' * 6,
      category: 'Kosmos',
      shortText: 'Bardzo długa zajawka ' * 20,
      longText: 'Rozwinięcie',
      source: 'Źródło',
      createdAt: DateTime.utc(2026),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: ShareCardSheet(fact: longFact)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(CategoryBadge))).brightness,
      Brightness.light,
    );
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
