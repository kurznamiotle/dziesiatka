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

  factory UsageRow.fromRow(Map<String, dynamic> row) {
    return UsageRow(
      // Midnight in UTC, so adding days never crosses a clock change.
      day: DateTime.parse('${row['day']}T00:00:00Z'),
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
}
