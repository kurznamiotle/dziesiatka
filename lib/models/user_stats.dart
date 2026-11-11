/// The numbers shown under a finished deck.
class UserStats {
  const UserStats({
    required this.daysCompleted,
    required this.factsRead,
    required this.factsRemembered,
    required this.answersGiven,
    required this.answersCorrect,
    this.favoriteCategory,
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

  /// The share of correct answers from 0 to 100, or null without answers.
  int? get accuracyPercent {
    if (answersGiven == 0) return null;
    return (answersCorrect * 100 / answersGiven).round();
  }
}
