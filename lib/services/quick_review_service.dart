import 'dart:math';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/quiz_record.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/quiz_history_service.dart';

/// Picks a few quiz questions about facts read on earlier days. It is apart
/// from the daily deck, so it changes neither the streak nor today's score.
class QuickReviewService {
  QuickReviewService(
    this._factsService,
    this._quizHistory, {
    DateTime Function()? now,
    Random? random,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random();

  static const questionCount = 3;

  final FactsService _factsService;
  final QuizHistoryService _quizHistory;
  final DateTime Function() _now;
  final Random _random;

  /// The facts to ask about, in order. Empty before anything was read on an
  /// earlier day.
  Future<List<Fact>> chooseFacts() async {
    return choose(
      await _factsService.getFacts(),
      await _quizHistory.getRecords(),
    );
  }

  /// Facts answered wrong last time come first, then those not seen for the
  /// longest time. Ties are broken at random so the same facts do not always
  /// win.
  List<Fact> choose(List<Fact> facts, Map<String, QuizRecord> records) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final candidates = facts.where((fact) {
      final readAt = fact.lastReadAt;
      return fact.quiz != null &&
          !fact.isPartner &&
          fact.isRead &&
          !fact.isWithdrawn &&
          (readAt == null || readAt.isBefore(today));
    }).toList();

    final tieBreak = {
      for (final fact in candidates) fact.id: _random.nextInt(1 << 30),
    };
    final oldest = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime lastSeen(Fact fact) {
      final answeredAt = records[fact.id]?.lastAnsweredAt;
      final readAt = fact.lastReadAt ?? oldest;
      if (answeredAt == null) return readAt;
      return answeredAt.isAfter(readAt) ? answeredAt : readAt;
    }

    bool wasWrong(Fact fact) => records[fact.id]?.wasLastCorrect == false;

    candidates.sort((first, second) {
      if (wasWrong(first) != wasWrong(second)) return wasWrong(first) ? -1 : 1;
      final bySeen = lastSeen(first).compareTo(lastSeen(second));
      if (bySeen != 0) return bySeen;
      return tieBreak[first.id]!.compareTo(tieBreak[second.id]!);
    });
    return candidates.take(questionCount).toList();
  }

  Future<void> recordAnswer(String factId, {required bool isCorrect}) {
    return _quizHistory.recordAnswer(factId, isCorrect: isCorrect);
  }
}
