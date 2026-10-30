import 'package:dziesiatka/models/completed_card.dart';

/// The cards chosen for one calendar day. Progress lives here and not in
/// `Fact.isRead`, because a deck can repeat facts that were read on earlier days.
class DailyDeck {
  const DailyDeck({
    required this.date,
    required this.factIds,
    this.completed = const [],
  });

  factory DailyDeck.fromJson(Map<String, dynamic> json) {
    return DailyDeck(
      date: json['date'] as String,
      factIds: (json['factIds'] as List<dynamic>).cast<String>(),
      completed: (json['completed'] as List<dynamic>)
          .map((item) => CompletedCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// The local calendar day as `yyyy-mm-dd`.
  final String date;
  final List<String> factIds;
  final List<CompletedCard> completed;

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
    return DailyDeck(
      date: date,
      factIds: factIds,
      completed: [...completed, card],
    );
  }

  DailyDeck withoutLastCompleted() {
    return DailyDeck(
      date: date,
      factIds: factIds,
      completed: completed.sublist(0, completed.length - 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'factIds': factIds,
      'completed': completed.map((card) => card.toJson()).toList(),
    };
  }
}
