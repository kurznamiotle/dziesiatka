import 'package:dziesiatka/models/completed_card.dart';

/// The cards chosen for one calendar day. Progress lives here and not in
/// `Fact.isRead`, because a deck can repeat facts that were read on earlier days.
class DailyDeck {
  const DailyDeck({
    required this.date,
    required this.factIds,
    this.quizFactIds = const [],
    this.reviewFactIds = const [],
    this.completed = const [],
    this.quizCorrect,
  });

  factory DailyDeck.fromJson(Map<String, dynamic> json) {
    final quizFactIds = json['quizFactIds'] as List<dynamic>?;
    final reviewFactIds = json['reviewFactIds'] as List<dynamic>?;
    return DailyDeck(
      date: json['date'] as String,
      factIds: (json['factIds'] as List<dynamic>).cast<String>(),
      quizFactIds: quizFactIds?.cast<String>() ?? const [],
      reviewFactIds: reviewFactIds?.cast<String>() ?? const [],
      completed: (json['completed'] as List<dynamic>)
          .map((item) => CompletedCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      quizCorrect: json['quizCorrect'] as int?,
    );
  }

  /// The local calendar day as `yyyy-mm-dd`.
  final String date;
  final List<String> factIds;

  /// The facts whose questions make up today's quiz.
  final List<String> quizFactIds;

  /// The facts that had already been read when the deck was chosen. Finishing
  /// a card marks it read, so this cannot be worked out from the facts later.
  final List<String> reviewFactIds;
  final List<CompletedCard> completed;

  /// Correct answers in today's quiz, or null until it is finished.
  final int? quizCorrect;

  static String dateKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$dayOfMonth';
  }

  /// The local midnight that ends this deck.
  DateTime get expiresAt {
    final day = DateTime.parse(date);
    return DateTime(day.year, day.month, day.day + 1);
  }

  List<String> get remainingIds {
    final completedIds = completed.map((card) => card.factId).toSet();
    return factIds.where((id) => !completedIds.contains(id)).toList();
  }

  DailyDeck withCompleted(CompletedCard card) {
    return _copyWith(completed: [...completed, card]);
  }

  DailyDeck withoutLastCompleted() {
    return _copyWith(completed: completed.sublist(0, completed.length - 1));
  }

  DailyDeck withQuizResult(int correct) => _copyWith(quizCorrect: correct);

  DailyDeck _copyWith({List<CompletedCard>? completed, int? quizCorrect}) {
    return DailyDeck(
      date: date,
      factIds: factIds,
      quizFactIds: quizFactIds,
      reviewFactIds: reviewFactIds,
      completed: completed ?? this.completed,
      quizCorrect: quizCorrect ?? this.quizCorrect,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'factIds': factIds,
      'quizFactIds': quizFactIds,
      'reviewFactIds': reviewFactIds,
      'completed': completed.map((card) => card.toJson()).toList(),
      'quizCorrect': quizCorrect,
    };
  }
}
