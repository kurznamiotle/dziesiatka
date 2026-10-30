import 'package:dziesiatka/services/share_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gal');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late bool hasAccess;
  late bool grantsAccess;

  setUp(() {
    calls = [];
    hasAccess = true;
    grantsAccess = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'hasAccess' => hasAccess,
        'requestAccess' => grantsAccess,
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  MethodCall? saved() {
    return calls.where((call) => call.method == 'putImageBytes').firstOrNull;
  }

  group('on Android', () {
    const shareChannel = MethodChannel('dziesiatka/share');
    late List<MethodCall> shares;

    setUp(() {
      shares = [];
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        shares.add(call);
        return null;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(shareChannel, null));

    test('shares through the sheet without Reels targets', () async {
      await const ShareService().shareImage(
        Uint8List.fromList([1, 2, 3]),
        fileName: 'dziesiatka-story.png',
        title: 'Tytuł',
      );

      expect(shares.single.method, 'shareImage');
      expect(shares.single.arguments, {
        'bytes': Uint8List.fromList([1, 2, 3]),
        'fileName': 'dziesiatka-story.png',
        'title': 'Tytuł',
      });
    });

    test('reports a sheet that fails to open', () async {
      messenger.setMockMethodCallHandler(shareChannel, (_) async {
        throw PlatformException(code: 'share_failed');
      });

      await expectLater(
        const ShareService().shareImage(
          Uint8List.fromList([1]),
          fileName: 'dziesiatka-story.png',
          title: 'Tytuł',
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  test('gives the gallery a name without the extension', () async {
    await const ShareService().saveImage(
      Uint8List.fromList([1, 2, 3]),
      fileName: 'dziesiatka-story.png',
    );

    expect(saved()!.arguments['name'], 'dziesiatka-story');
  });

  test('asks for gallery access when it is missing', () async {
    hasAccess = false;

    await const ShareService().saveImage(
      Uint8List.fromList([1]),
      fileName: 'dziesiatka-story.png',
    );

    expect(saved(), isNotNull);
  });

  test('saves nothing when gallery access is refused', () async {
    hasAccess = false;
    grantsAccess = false;

    await expectLater(
      const ShareService().saveImage(
        Uint8List.fromList([1]),
        fileName: 'dziesiatka-story.png',
      ),
      throwsStateError,
    );

    expect(saved(), isNull);
  });
}
