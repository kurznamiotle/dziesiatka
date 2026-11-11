import 'package:dziesiatka/models/achievement_progress.dart';
import 'package:dziesiatka/services/achievements_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = AchievementsService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<List<String>> check(AchievementProgress progress) async {
    final earned = await service.checkProgress(progress);
    return earned.map((item) => item.id).toList();
  }

  test('an ordinary day unlocks nothing', () async {
    expect(
      await check(const AchievementProgress(streak: 1, factsRead: 10)),
      isEmpty,
    );
  });

  test('a streak milestone unlocks once', () async {
    expect(await check(const AchievementProgress(streak: 5)), ['streak-5']);
    expect(await check(const AchievementProgress(streak: 5)), isEmpty);
  });

  test('reaching a far goal also unlocks those before it', () async {
    expect(await check(const AchievementProgress(streak: 10)), [
      'streak-5',
      'streak-10',
    ]);
  });

  test('an unlocked achievement stays after a lost streak', () async {
    await check(const AchievementProgress(streak: 5));

    await check(const AchievementProgress(streak: 1));

    expect(await service.getUnlockedIds(), {'streak-5'});
  });

  test('a new achievement never unlocks a second time', () async {
    const progress = AchievementProgress(shares: 1, reviews: 1);
    expect(await check(progress), ['review-1', 'share-1']);

    expect(await check(progress), isEmpty);
    expect(await check(const AchievementProgress(shares: 9)), isEmpty);
  });

  test('an older user gets everything already reached at once', () async {
    SharedPreferences.setMockInitialValues({
      'unlockedAchievements': ['read-100'],
    });

    expect(await check(const AchievementProgress(factsRead: 300)), [
      'read-250',
    ]);
  });

  group('counts', () {
    test('start at 0', () async {
      final counts = await service.getCounts();

      expect(counts.perfectQuizzes, 0);
      expect(counts.reviews, 0);
      expect(counts.perfectReviews, 0);
      expect(counts.shares, 0);
    });

    test(
      'perfect quizzes add up and keep the count of older versions',
      () async {
        SharedPreferences.setMockInitialValues({'perfectQuizCount': 9});

        await service.recordQuiz(wasPerfect: true);
        await service.recordQuiz(wasPerfect: false);

        expect((await service.getCounts()).perfectQuizzes, 10);
      },
    );

    test('a review counts, a perfect one counts twice', () async {
      await service.recordReview(wasPerfect: false);
      await service.recordReview(wasPerfect: true);

      final counts = await service.getCounts();
      expect(counts.reviews, 2);
      expect(counts.perfectReviews, 1);
    });

    test('shares add up', () async {
      await service.recordShare();
      await service.recordShare();

      expect((await service.getCounts()).shares, 2);
    });
  });
}
