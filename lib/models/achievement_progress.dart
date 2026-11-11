/// The numbers that achievements are measured against.
class AchievementProgress {
  const AchievementProgress({
    this.streak = 0,
    this.daysTotal = 0,
    this.factsRead = 0,
    this.categoriesRead = 0,
    this.categoriesTotal = 0,
    this.favorites = 0,
    this.perfectQuizzes = 0,
    this.remembered = 0,
    this.reviews = 0,
    this.perfectReviews = 0,
    this.shares = 0,
  });

  final int streak;

  /// Every day with a finished deck, not only the current streak.
  final int daysTotal;
  final int factsRead;

  /// Categories with at least one read fact, out of [categoriesTotal] that the
  /// app knows.
  final int categoriesRead;
  final int categoriesTotal;
  final int favorites;
  final int perfectQuizzes;

  /// Facts whose quiz question was answered right the last time.
  final int remembered;

  /// Finished quick reviews, and those among them without a mistake.
  final int reviews;
  final int perfectReviews;
  final int shares;
}
