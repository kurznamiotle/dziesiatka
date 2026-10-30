import 'dart:convert';
import 'dart:math';

import 'package:dziesiatka/models/completed_card.dart';
import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/daily_session.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyDeckService {
  DailyDeckService(
    this._factsService,
    this._streakService, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const deckSize = 10;
  static const reviewCount = 3;
  static const quizQuestionCount = 2;
  static const _deckKey = 'dailyDeck';

  final FactsService _factsService;
  final StreakService _streakService;
  final DateTime Function() _now;

  /// Returns today's deck, choosing and saving a new one on the first call of
  /// each day, so the cards stay the same across restarts.
  Future<DailySession> loadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await _factsService.getFacts();
    final streak = await _streakService.getCurrentStreak();
    final today = DailyDeck.dateKey(_now());
    final factIds = facts.map((fact) => fact.id).toSet();

    final stored = _readDeck(prefs);
    if (stored != null &&
        stored.date == today &&
        stored.factIds.every(factIds.contains)) {
      return DailySession(deck: stored, pool: facts, streak: streak);
    }

    final chosen = _chooseFacts(facts);
    final deck = DailyDeck(
      date: today,
      factIds: chosen.map((fact) => fact.id).toList(),
      quizFactIds: _chooseQuizFactIds(chosen),
    );
    await _saveDeck(prefs, deck);
    return DailySession(deck: deck, pool: facts, streak: streak);
  }

  /// Finishes a card. It does nothing for a card outside today's remaining
  /// cards, which happens when the app stays open past midnight.
  Future<DailySession> completeCard(
    String factId, {
    required bool liked,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final session = await loadToday();
    if (!session.deck.remainingIds.contains(factId)) return session;

    final fact = session.facts.firstWhere((fact) => fact.id == factId);
    await _factsService.setCardState(
      factId,
      isRead: true,
      isFavorite: liked || fact.isFavorite,
    );
    await _saveDeck(
      prefs,
      session.deck.withCompleted(
        CompletedCard(
          factId: factId,
          wasRead: fact.isRead,
          wasFavorite: fact.isFavorite,
        ),
      ),
    );

    final updated = await loadToday();
    if (updated.remaining.isNotEmpty || updated.isQuizPending) return updated;

    // A deck without questions has no quiz to count as the finish.
    await _streakService.recordCompletion();
    return loadToday();
  }

  /// Brings the last finished card back and restores its previous state.
  Future<DailySession> undo() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await loadToday();
    if (!session.canUndo) return session;

    final last = session.deck.completed.last;
    await _factsService.setCardState(
      last.factId,
      isRead: last.wasRead,
      isFavorite: last.wasFavorite,
    );
    await _saveDeck(prefs, session.deck.withoutLastCompleted());
    return loadToday();
  }

  /// Saves the quiz score and counts the day toward the streak, because the
  /// quiz is the last step of the daily deck.
  Future<DailySession> finishQuiz(int correct) async {
    final prefs = await SharedPreferences.getInstance();
    final session = await loadToday();
    if (!session.isQuizPending) return session;

    await _saveDeck(prefs, session.deck.withQuizResult(correct));
    await _streakService.recordCompletion();
    return loadToday();
  }

  Duration timeUntilNextDeck(DailySession session) {
    return session.deck.expiresAt.difference(_now());
  }

  int get _dayNumber {
    final today = _now();
    final day = DateTime.utc(today.year, today.month, today.day);
    return day.difference(DateTime.utc(1970)).inDays;
  }

  /// Mixes new facts with a few reviews of read ones. When either kind runs
  /// out, the other fills the deck. The read facts start from a point that
  /// moves each day, so reviews change between days.
  List<Fact> _chooseFacts(List<Fact> facts) {
    final unread = facts.where((fact) => !fact.isRead).toList();
    final read = facts.where((fact) => fact.isRead).toList();

    final start = read.isEmpty ? 0 : _dayNumber % read.length;
    final reviews = [...read.skip(start), ...read.take(start)];

    final newCount = min<int>(
      deckSize - min<int>(reviewCount, read.length),
      unread.length,
    );
    return [...unread.take(newCount), ...reviews.take(deckSize - newCount)];
  }

  List<String> _chooseQuizFactIds(List<Fact> deckFacts) {
    final withQuestions = deckFacts.where((fact) => fact.quiz != null).toList()
      ..shuffle(Random(_dayNumber));
    return withQuestions
        .take(quizQuestionCount)
        .map((fact) => fact.id)
        .toList();
  }

  DailyDeck? _readDeck(SharedPreferences prefs) {
    final stored = prefs.getString(_deckKey);
    if (stored == null) return null;
    return DailyDeck.fromJson(jsonDecode(stored) as Map<String, dynamic>);
  }

  Future<void> _saveDeck(SharedPreferences prefs, DailyDeck deck) async {
    await prefs.setString(_deckKey, jsonEncode(deck.toJson()));
  }
}
