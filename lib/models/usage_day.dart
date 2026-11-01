/// What one installation did on one day, kept on the device until it is sent.
/// The optional fields stay null on days when they say nothing.
class UsageDay {
  const UsageDay({
    required this.date,
    this.cardsCompleted = 0,
    this.deckFinished = false,
    this.quizCorrect,
    this.quizTotal,
    this.bonusRounds = 0,
    this.streakBucket,
    this.categoriesChanged = false,
    this.remindersEnabled,
    this.instructions,
    this.choseAllCategories,
    this.notificationsAllowed,
    this.isSent = false,
  });

  factory UsageDay.fromJson(Map<String, dynamic> json) {
    return UsageDay(
      date: json['date'] as String,
      cardsCompleted: json['cardsCompleted'] as int,
      deckFinished: json['deckFinished'] as bool,
      quizCorrect: json['quizCorrect'] as int?,
      quizTotal: json['quizTotal'] as int?,
      bonusRounds: json['bonusRounds'] as int,
      streakBucket: json['streakBucket'] as String?,
      categoriesChanged: json['categoriesChanged'] as bool,
      remindersEnabled: json['remindersEnabled'] as bool?,
      instructions: json['instructions'] as String?,
      choseAllCategories: json['choseAllCategories'] as bool?,
      notificationsAllowed: json['notificationsAllowed'] as bool?,
      isSent: json['isSent'] as bool,
    );
  }

  /// The local calendar day as `yyyy-mm-dd`.
  final String date;
  final int cardsCompleted;
  final bool deckFinished;
  final int? quizCorrect;
  final int? quizTotal;
  final int bonusRounds;

  /// A range rather than the exact streak, see [bucketOf].
  final String? streakBucket;
  final bool categoriesChanged;
  final bool? remindersEnabled;

  /// `finished` or `skipped`, on the day of the first run.
  final String? instructions;
  final bool? choseAllCategories;
  final bool? notificationsAllowed;

  /// False until the current numbers reach the server.
  final bool isSent;

  static String bucketOf(int streak) {
    if (streak == 0) return '0';
    if (streak < 5) return '1-4';
    if (streak < 10) return '5-9';
    return '10+';
  }

  /// Any change means there is something new to send.
  UsageDay copyWith({
    int? cardsCompleted,
    bool? deckFinished,
    int? quizCorrect,
    int? quizTotal,
    int? bonusRounds,
    String? streakBucket,
    bool? categoriesChanged,
    bool? remindersEnabled,
    String? instructions,
    bool? choseAllCategories,
    bool? notificationsAllowed,
  }) {
    return UsageDay(
      date: date,
      cardsCompleted: cardsCompleted ?? this.cardsCompleted,
      deckFinished: deckFinished ?? this.deckFinished,
      quizCorrect: quizCorrect ?? this.quizCorrect,
      quizTotal: quizTotal ?? this.quizTotal,
      bonusRounds: bonusRounds ?? this.bonusRounds,
      streakBucket: streakBucket ?? this.streakBucket,
      categoriesChanged: categoriesChanged ?? this.categoriesChanged,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      instructions: instructions ?? this.instructions,
      choseAllCategories: choseAllCategories ?? this.choseAllCategories,
      notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
    );
  }

  UsageDay asSent() {
    return UsageDay(
      date: date,
      cardsCompleted: cardsCompleted,
      deckFinished: deckFinished,
      quizCorrect: quizCorrect,
      quizTotal: quizTotal,
      bonusRounds: bonusRounds,
      streakBucket: streakBucket,
      categoriesChanged: categoriesChanged,
      remindersEnabled: remindersEnabled,
      instructions: instructions,
      choseAllCategories: choseAllCategories,
      notificationsAllowed: notificationsAllowed,
      isSent: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'cardsCompleted': cardsCompleted,
      'deckFinished': deckFinished,
      'quizCorrect': quizCorrect,
      'quizTotal': quizTotal,
      'bonusRounds': bonusRounds,
      'streakBucket': streakBucket,
      'categoriesChanged': categoriesChanged,
      'remindersEnabled': remindersEnabled,
      'instructions': instructions,
      'choseAllCategories': choseAllCategories,
      'notificationsAllowed': notificationsAllowed,
      'isSent': isSent,
    };
  }

  /// The numbers for the `record_usage_day` function.
  Map<String, dynamic> toRow() {
    return {
      'day': date,
      'cards_completed': cardsCompleted,
      'deck_finished': deckFinished,
      'quiz_correct': quizCorrect,
      'quiz_total': quizTotal,
      'bonus_rounds': bonusRounds,
      'streak_bucket': streakBucket,
      'categories_changed': categoriesChanged,
      'reminders_enabled': remindersEnabled,
      'instructions': instructions,
      'chose_all_categories': choseAllCategories,
      'notifications_allowed': notificationsAllowed,
    };
  }
}
