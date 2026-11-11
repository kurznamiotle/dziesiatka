import 'package:dziesiatka/models/achievement.dart';
import 'package:dziesiatka/models/achievement_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// A progress where only [kind] has [value].
AchievementProgress _progressOf(AchievementKind kind, int value) {
  return switch (kind) {
    AchievementKind.streak => AchievementProgress(streak: value),
    AchievementKind.daysTotal => AchievementProgress(daysTotal: value),
    AchievementKind.factsRead => AchievementProgress(factsRead: value),
    AchievementKind.categoriesRead => AchievementProgress(
      categoriesRead: value,
      categoriesTotal: 12,
    ),
    AchievementKind.favorites => AchievementProgress(favorites: value),
    AchievementKind.perfectQuizzes => AchievementProgress(
      perfectQuizzes: value,
    ),
    AchievementKind.remembered => AchievementProgress(remembered: value),
    AchievementKind.reviews => AchievementProgress(reviews: value),
    AchievementKind.perfectReviews => AchievementProgress(
      perfectReviews: value,
    ),
    AchievementKind.shares => AchievementProgress(shares: value),
  };
}

Achievement _byId(String id) {
  return Achievement.all.firstWhere((achievement) => achievement.id == id);
}

void main() {
  test('there are 20 achievements with distinct ids', () {
    expect(Achievement.all, hasLength(20));
    expect(Achievement.all.map((item) => item.id).toSet(), hasLength(20));
  });

  group('each new achievement unlocks exactly at its goal', () {
    const counted = {
      'read-250': 250,
      'days-30': 30,
      'days-100': 100,
      'remembered-50': 50,
      'remembered-200': 200,
      'review-1': 1,
      'review-perfect-10': 10,
      'favorites-25': 25,
      'share-1': 1,
      'perfect-50': 50,
    };

    for (final MapEntry(key: id, value: goal) in counted.entries) {
      test(id, () {
        final achievement = _byId(id);

        expect(achievement.goal, goal);
        expect(
          achievement.isReachedBy(_progressOf(achievement.kind, goal - 1)),
          isFalse,
        );
        expect(
          achievement.isReachedBy(_progressOf(achievement.kind, goal)),
          isTrue,
        );
      });
    }

    test('categories-all needs every category the app knows', () {
      final achievement = _byId('categories-all');

      expect(
        achievement.isReachedBy(
          const AchievementProgress(categoriesRead: 11, categoriesTotal: 12),
        ),
        isFalse,
      );
      expect(
        achievement.isReachedBy(
          const AchievementProgress(categoriesRead: 12, categoriesTotal: 12),
        ),
        isTrue,
      );
      expect(
        achievement.isReachedBy(
          const AchievementProgress(categoriesRead: 14, categoriesTotal: 14),
        ),
        isTrue,
      );
    });

    test('categories-all is not reached before any facts are known', () {
      expect(
        _byId('categories-all').isReachedBy(const AchievementProgress()),
        isFalse,
      );
    });
  });

  test('each kind counts only its own number', () {
    for (final achievement in Achievement.all) {
      for (final other in AchievementKind.values) {
        if (other == achievement.kind) continue;
        expect(
          achievement.isReachedBy(_progressOf(other, 1000)),
          isFalse,
          reason: '${achievement.id} with $other',
        );
      }
    }
  });
}
