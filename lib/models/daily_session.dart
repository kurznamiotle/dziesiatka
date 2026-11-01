import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';

/// A [DailyDeck] resolved to its facts, in deck order, with the current streak.
class DailySession {
  DailySession({
    required this.deck,
    required List<Fact> pool,
    required this.streak,
    this.bonusCount = 0,
  }) : facts = [
         for (final id in deck.factIds)
           pool.firstWhere((fact) => fact.id == id),
       ],
       factsRead = pool.where((fact) => fact.isRead).length;

  final DailyDeck deck;
  final List<Fact> facts;
  final int streak;

  /// How many extra cards the next "Jeszcze" round would bring.
  final int bonusCount;

  /// All facts this user has read, not only those in today's deck.
  final int factsRead;

  List<Fact> get remaining {
    final remainingIds = deck.remainingIds.toSet();
    return facts.where((fact) => remainingIds.contains(fact.id)).toList();
  }

  int get completedCount => deck.completed.length;

  bool get canUndo => deck.completed.length > deck.lockedCount;

  List<QuizQuestion> get quizQuestions {
    return [
      for (final id in deck.quizFactIds)
        ?facts.firstWhere((fact) => fact.id == id).quiz,
    ];
  }

  /// The facts behind [quizQuestions], in the same order.
  List<Fact> get quizFacts {
    return [
      for (final id in deck.quizFactIds)
        for (final fact in facts)
          if (fact.id == id && fact.quiz != null) fact,
    ];
  }

  /// All cards are done and the quiz still has to be answered.
  bool get isQuizPending {
    return facts.isNotEmpty &&
        remaining.isEmpty &&
        quizQuestions.isNotEmpty &&
        deck.quizCorrect == null;
  }

  /// Today's required part is done and counts toward the streak. It stays true
  /// while the user goes through bonus cards.
  bool get isDayFinished {
    if (deck.quizCorrect != null) return true;
    return facts.isNotEmpty && remaining.isEmpty && quizQuestions.isEmpty;
  }
}
