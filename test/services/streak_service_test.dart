import 'package:dziesiatka/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late StreakService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 2, 12);
    service = StreakService(now: () => now);
  });

  test('starts at 0', () async {
    expect(await service.getCurrentStreak(), 0);
  });

  test('the first completion starts a streak of 1', () async {
    await service.recordCompletion();

    expect(await service.getCurrentStreak(), 1);
  });

  test('a second completion on the same day counts once', () async {
    await service.recordCompletion();
    await service.recordCompletion();

    expect(await service.getCurrentStreak(), 1);
  });

  test('grows when decks are finished on consecutive days', () async {
    await service.recordCompletion();
    now = now.add(const Duration(days: 1));
    await service.recordCompletion();
    now = now.add(const Duration(days: 1));
    await service.recordCompletion();

    expect(await service.getCurrentStreak(), 3);
  });

  test('stays visible on the day after the last completion', () async {
    await service.recordCompletion();

    now = now.add(const Duration(days: 1));

    expect(await service.getCurrentStreak(), 1);
  });

  test('shows 0 once a whole day was missed', () async {
    await service.recordCompletion();

    now = now.add(const Duration(days: 2));

    expect(await service.getCurrentStreak(), 0);
  });

  test('restarts at 1 after a gap', () async {
    await service.recordCompletion();
    now = now.add(const Duration(days: 1));
    await service.recordCompletion();

    now = now.add(const Duration(days: 2));
    await service.recordCompletion();

    expect(await service.getCurrentStreak(), 1);
  });

  test('counts calendar days and not 24 hour periods', () async {
    now = DateTime(2026, 11, 2, 23, 50);
    await service.recordCompletion();

    now = DateTime(2026, 11, 3, 0, 10);
    await service.recordCompletion();

    expect(await service.getCurrentStreak(), 2);
  });

  test('crosses a month boundary', () async {
    now = DateTime(2026, 10, 31, 20);
    await service.recordCompletion();

    now = DateTime(2026, 11, 1, 8);
    await service.recordCompletion();

    expect(await service.getCurrentStreak(), 2);
  });

  test('survives a new service instance', () async {
    await service.recordCompletion();

    expect(await StreakService(now: () => now).getCurrentStreak(), 1);
  });
}
