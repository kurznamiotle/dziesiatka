import 'package:dziesiatka/services/quiz_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late QuizHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 2, 12);
    service = QuizHistoryService(now: () => now);
  });

  test('is empty before any answer', () async {
    expect(await service.getRecords(), isEmpty);
  });

  test('counts answers and keeps the latest one', () async {
    await service.recordAnswer('fact-1', isCorrect: true);
    now = DateTime(2026, 11, 4, 9);
    await service.recordAnswer('fact-1', isCorrect: false);

    final record = (await service.getRecords())['fact-1']!;

    expect(record.answered, 2);
    expect(record.correct, 1);
    expect(record.wasLastCorrect, isFalse);
    expect(record.lastAnsweredAt, DateTime(2026, 11, 4, 9));
  });

  test('keeps facts apart and survives a new instance', () async {
    await service.recordAnswer('fact-1', isCorrect: true);
    await service.recordAnswer('fact-2', isCorrect: false);

    final records = await QuizHistoryService().getRecords();

    expect(records.keys, ['fact-1', 'fact-2']);
    expect(records['fact-1']!.wasLastCorrect, isTrue);
    expect(records['fact-2']!.wasLastCorrect, isFalse);
  });
}
