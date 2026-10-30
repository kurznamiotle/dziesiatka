import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_question.dart';

/// A [DailyDeck] resolved to its facts, in deck order, with the current streak.
class DailySession {
  DailySession({
    required this.deck,
    required List<Fact> pool,
    required this.streak,
  }) : facts = [
         for (final id in deck.factIds)
           pool.firstWhere((fact) => fact.id == id),
       ];

  final DailyDeck deck;
  final List<Fact> facts;
  final int streak;

  List<Fact> get remaining {
    final remainingIds = deck.remainingIds.toSet();
    return facts.where((fact) => remainingIds.contains(fact.id)).toList();
  }

  int get completedCount => deck.completed.length;

  bool get canUndo => deck.completed.isNotEmpty;

  List<QuizQuestion> get quizQuestions {
    return [
      for (final id in deck.quizFactIds)
        ?facts.firstWhere((fact) => fact.id == id).quiz,
    ];
  }

  /// All cards are done and the quiz still has to be answered.
  bool get isQuizPending {
    return facts.isNotEmpty &&
        remaining.isEmpty &&
        quizQuestions.isNotEmpty &&
        deck.quizCorrect == null;
  }
}
