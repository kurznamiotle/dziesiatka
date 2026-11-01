/// One day on the dashboard.
class DailyUsage {
  const DailyUsage({
    required this.day,
    required this.activeUsers,
    required this.finishedDeck,
    required this.averageCards,
  });

  final DateTime day;
  final int activeUsers;
  final int finishedDeck;
  final double averageCards;
}

/// The numbers on the dashboard. Percentages are null while there is too
/// little data to calculate them.
class UsageSummary {
  const UsageSummary({
    required this.days,
    required this.installs,
    required this.returnedAfterDay,
    required this.returnedAfterWeek,
    required this.quizCorrectPercent,
    required this.bonusRounds,
    required this.finishedInstructions,
    required this.skippedInstructions,
    required this.choseAllCategories,
    required this.choseFavorites,
    required this.allowedNotifications,
    required this.deniedNotifications,
    required this.finishedFirstDeck,
  });

  /// Newest first.
  final List<DailyUsage> days;
  final int installs;
  final double? returnedAfterDay;
  final double? returnedAfterWeek;
  final double? quizCorrectPercent;
  final int bonusRounds;

  final int finishedInstructions;
  final int skippedInstructions;
  final int choseAllCategories;
  final int choseFavorites;
  final int allowedNotifications;
  final int deniedNotifications;
  final int finishedFirstDeck;
}
