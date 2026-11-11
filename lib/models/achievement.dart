import 'package:dziesiatka/models/achievement_progress.dart';

/// In the order the achievements screen groups them.
enum AchievementKind {
  streak,
  daysTotal,
  factsRead,
  categoriesRead,
  favorites,
  perfectQuizzes,
  remembered,
  reviews,
  perfectReviews,
  shares,
}

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
    Achievement(
      id: 'read-250',
      title: 'Mól książkowy',
      description: '250 przeczytanych ciekawostek',
      kind: AchievementKind.factsRead,
      goal: 250,
    ),
    Achievement(
      id: 'days-30',
      title: 'Stały bywalec',
      description: '30 dni z Dziesiątką',
      kind: AchievementKind.daysTotal,
      goal: 30,
    ),
    Achievement(
      id: 'days-100',
      title: 'Sto dni ciekawości',
      description: '100 dni z Dziesiątką',
      kind: AchievementKind.daysTotal,
      goal: 100,
    ),
    Achievement(
      id: 'remembered-50',
      title: 'Pamięć słonia',
      description: '50 zapamiętanych ciekawostek',
      kind: AchievementKind.remembered,
      goal: 50,
    ),
    Achievement(
      id: 'remembered-200',
      title: 'Głowa jak sejf',
      description: '200 zapamiętanych ciekawostek',
      kind: AchievementKind.remembered,
      goal: 200,
    ),
    Achievement(
      id: 'review-1',
      title: 'Powrót do przeszłości',
      description: 'Pierwsza szybka powtórka',
      kind: AchievementKind.reviews,
      goal: 1,
    ),
    Achievement(
      id: 'review-perfect-10',
      title: 'Nic nie umyka',
      description: '10 szybkich powtórek bez pomyłki',
      kind: AchievementKind.perfectReviews,
      goal: 10,
    ),
    Achievement(
      id: 'categories-all',
      title: 'Człowiek renesansu',
      description: 'Ciekawostka z każdej kategorii',
      kind: AchievementKind.categoriesRead,
      goal: 0,
    ),
    Achievement(
      id: 'favorites-25',
      title: 'Kolekcjoner',
      description: '25 polubionych ciekawostek',
      kind: AchievementKind.favorites,
      goal: 25,
    ),
    Achievement(
      id: 'share-1',
      title: 'Podaj dalej',
      description: 'Pierwsza udostępniona ciekawostka',
      kind: AchievementKind.shares,
      goal: 1,
    ),
    Achievement(
      id: 'perfect-50',
      title: 'Quizowy weteran',
      description: '50 quizów bez pomyłki',
      kind: AchievementKind.perfectQuizzes,
      goal: 50,
    ),
  ];

  final String id;
  final String title;
  final String description;
  final AchievementKind kind;

  /// The value to reach. [AchievementKind.categoriesRead] asks for every
  /// category the app knows, which can grow, so its goal is 0 here and comes
  /// from the progress instead.
  final int goal;

  bool isReachedBy(AchievementProgress progress) {
    if (kind == AchievementKind.categoriesRead) {
      return progress.categoriesTotal > 0 &&
          progress.categoriesRead >= progress.categoriesTotal;
    }
    final value = switch (kind) {
      AchievementKind.streak => progress.streak,
      AchievementKind.daysTotal => progress.daysTotal,
      AchievementKind.factsRead => progress.factsRead,
      AchievementKind.categoriesRead => progress.categoriesRead,
      AchievementKind.favorites => progress.favorites,
      AchievementKind.perfectQuizzes => progress.perfectQuizzes,
      AchievementKind.remembered => progress.remembered,
      AchievementKind.reviews => progress.reviews,
      AchievementKind.perfectReviews => progress.perfectReviews,
      AchievementKind.shares => progress.shares,
    };
    return value >= goal;
  }
}
