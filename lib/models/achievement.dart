import 'package:dziesiatka/models/achievement_progress.dart';

enum AchievementKind { streak, perfectQuizzes, factsRead }

/// A goal that stays unlocked once reached, even if a streak later ends.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.goal,
  });

  static const all = [
    Achievement(
      id: 'streak-5',
      title: 'Dobry początek',
      description: 'Seria 5 dni',
      kind: AchievementKind.streak,
      goal: 5,
    ),
    Achievement(
      id: 'streak-10',
      title: 'Pełna dziesiątka',
      description: 'Seria 10 dni',
      kind: AchievementKind.streak,
      goal: 10,
    ),
    Achievement(
      id: 'streak-25',
      title: 'Żelazny nawyk',
      description: 'Seria 25 dni',
      kind: AchievementKind.streak,
      goal: 25,
    ),
    Achievement(
      id: 'streak-50',
      title: 'Niezłomny',
      description: 'Seria 50 dni',
      kind: AchievementKind.streak,
      goal: 50,
    ),
    Achievement(
      id: 'streak-100',
      title: 'Legenda',
      description: 'Seria 100 dni',
      kind: AchievementKind.streak,
      goal: 100,
    ),
    Achievement(
      id: 'perfect-1',
      title: 'Bezbłędnie',
      description: 'Pierwszy quiz bez pomyłki',
      kind: AchievementKind.perfectQuizzes,
      goal: 1,
    ),
    Achievement(
      id: 'perfect-10',
      title: 'Mistrz quizów',
      description: '10 quizów bez pomyłki',
      kind: AchievementKind.perfectQuizzes,
      goal: 10,
    ),
    Achievement(
      id: 'read-100',
      title: 'Ciekawski',
      description: '100 przeczytanych ciekawostek',
      kind: AchievementKind.factsRead,
      goal: 100,
    ),
    Achievement(
      id: 'read-500',
      title: 'Chodząca encyklopedia',
      description: '500 przeczytanych ciekawostek',
      kind: AchievementKind.factsRead,
      goal: 500,
    ),
  ];

  final String id;
  final String title;
  final String description;
  final AchievementKind kind;
  final int goal;

  bool isReachedBy(AchievementProgress progress) {
    final value = switch (kind) {
      AchievementKind.streak => progress.streak,
      AchievementKind.perfectQuizzes => progress.perfectQuizzes,
      AchievementKind.factsRead => progress.factsRead,
    };
    return value >= goal;
  }
}
