/// The numbers shown under a finished deck.
class UserStats {
  const UserStats({
    required this.daysCompleted,
    required this.factsRead,
    required this.factsRemembered,
    required this.answersGiven,
    required this.answersCorrect,
    this.favoriteCategory,
    this.factsLiked = 0,
    this.categoriesRead = 0,
    this.categoriesTotal = 0,
  });

  /// Every day with a finished deck, not only the current streak.
  final int daysCompleted;
  final int factsRead;

  /// Facts whose quiz question was answered right the last time.
  final int factsRemembered;

  /// All quiz answers so far, counting repeats of the same question.
  final int answersGiven;
  final int answersCorrect;

  /// The category with the most liked facts, or null before the first like.
  final String? favoriteCategory;

  /// Liked facts, still liked now.
  final int factsLiked;

  /// Categories with at least one read fact, out of [categoriesTotal] in the
  /// facts still in circulation.
  final int categoriesRead;
  final int categoriesTotal;

  /// The share of correct answers from 0 to 100, or null without answers.
  int? get accuracyPercent {
    if (answersGiven == 0) return null;
    return (answersCorrect * 100 / answersGiven).round();
  }
}
