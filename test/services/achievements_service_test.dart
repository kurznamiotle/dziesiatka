import 'package:dziesiatka/services/achievements_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = AchievementsService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<List<String>> recordDay({
    int streak = 1,
    int factsRead = 10,
    bool wasQuizPerfect = false,
  }) async {
    final earned = await service.recordDay(
      streak: streak,
      factsRead: factsRead,
      wasQuizPerfect: wasQuizPerfect,
    );
    return earned.map((item) => item.id).toList();
  }

  test('an ordinary day unlocks nothing', () async {
    expect(await recordDay(), isEmpty);
  });

  test('a streak milestone unlocks once', () async {
    expect(await recordDay(streak: 5), ['streak-5']);
    expect(await recordDay(streak: 5), isEmpty);
  });

  test('reaching a far goal also unlocks those before it', () async {
    expect(await recordDay(streak: 10), ['streak-5', 'streak-10']);
  });

  test('perfect quizzes add up across days', () async {
    expect(await recordDay(wasQuizPerfect: true), ['perfect-1']);
    for (var day = 2; day < 10; day++) {
      expect(await recordDay(wasQuizPerfect: true), isEmpty);
    }

    expect(await recordDay(wasQuizPerfect: true), ['perfect-10']);
  });

  test('read facts unlock their goal', () async {
    expect(await recordDay(factsRead: 100), ['read-100']);
  });

  test('an unlocked achievement stays after a lost streak', () async {
    await recordDay(streak: 5);

    await recordDay(streak: 1);

    expect(await service.getUnlockedIds(), {'streak-5'});
  });
}
