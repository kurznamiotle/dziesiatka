/// One row of the `usage_days` table.
class UsageRow {
  const UsageRow({
    required this.day,
    required this.installId,
    this.cardsCompleted = 0,
    this.deckFinished = false,
    this.quizCorrect,
    this.quizTotal,
    this.bonusRounds = 0,
    this.instructions,
    this.choseAllCategories,
    this.notificationsAllowed,
  });

  /// Takes the Polish day the server set (`supabase/usage_03.sql`), and the
  /// device's own day before that file runs.
  factory UsageRow.fromRow(Map<String, dynamic> row) {
    return UsageRow(
      // Midnight in UTC, so adding days never crosses a clock change.
      day: DateTime.parse('${row['warsaw_day'] ?? row['day']}T00:00:00Z'),
      installId: row['install_id'] as String,
      cardsCompleted: row['cards_completed'] as int,
      deckFinished: row['deck_finished'] as bool,
      quizCorrect: row['quiz_correct'] as int?,
      quizTotal: row['quiz_total'] as int?,
      bonusRounds: row['bonus_rounds'] as int,
      instructions: row['instructions'] as String?,
      choseAllCategories: row['chose_all_categories'] as bool?,
      notificationsAllowed: row['notifications_allowed'] as bool?,
    );
  }

  /// The day in Poland, which the panel groups by.
  final DateTime day;
  final String installId;
  final int cardsCompleted;
  final bool deckFinished;
  final int? quizCorrect;
  final int? quizTotal;
  final int bonusRounds;
  final String? instructions;
  final bool? choseAllCategories;
  final bool? notificationsAllowed;

  /// Joins two rows of one installation that fell on the same Polish day,
  /// which happens to a device in a far time zone. Counts add up, and a
  /// finished deck or an answer from either row counts.
  UsageRow mergedWith(UsageRow other) {
    int? sum(int? first, int? second) {
      if (first == null && second == null) return null;
      return (first ?? 0) + (second ?? 0);
    }

    return UsageRow(
      day: day,
      installId: installId,
      cardsCompleted: cardsCompleted + other.cardsCompleted,
      deckFinished: deckFinished || other.deckFinished,
      quizCorrect: sum(quizCorrect, other.quizCorrect),
      quizTotal: sum(quizTotal, other.quizTotal),
      bonusRounds: bonusRounds + other.bonusRounds,
      instructions: instructions ?? other.instructions,
      choseAllCategories: choseAllCategories ?? other.choseAllCategories,
      notificationsAllowed: notificationsAllowed ?? other.notificationsAllowed,
    );
  }
}
