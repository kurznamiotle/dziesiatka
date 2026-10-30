import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/fact.dart';

/// A [DailyDeck] resolved to its facts, in deck order.
class DailySession {
  DailySession({required this.deck, required List<Fact> pool})
    : facts = [
        for (final id in deck.factIds) pool.firstWhere((fact) => fact.id == id),
      ];

  final DailyDeck deck;
  final List<Fact> facts;

  List<Fact> get remaining {
    final remainingIds = deck.remainingIds.toSet();
    return facts.where((fact) => remainingIds.contains(fact.id)).toList();
  }

  int get completedCount => deck.completed.length;

  bool get canUndo => deck.completed.isNotEmpty;
}
