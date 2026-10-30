import 'dart:convert';

import 'package:dziesiatka/models/completed_card.dart';
import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/daily_session.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyDeckService {
  DailyDeckService(this._factsService, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const deckSize = 10;
  static const _deckKey = 'dailyDeck';

  final FactsService _factsService;
  final DateTime Function() _now;

  /// Returns today's deck, choosing and saving a new one on the first call of
  /// each day, so the cards stay the same across restarts.
  Future<DailySession> loadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await _factsService.getFacts();
    final today = DailyDeck.dateKey(_now());
    final factIds = facts.map((fact) => fact.id).toSet();

    final stored = _readDeck(prefs);
    if (stored != null &&
        stored.date == today &&
        stored.factIds.every(factIds.contains)) {
      return DailySession(deck: stored, pool: facts);
    }

    final deck = DailyDeck(date: today, factIds: _chooseFactIds(facts));
    await _saveDeck(prefs, deck);
    return DailySession(deck: deck, pool: facts);
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

  Duration timeUntilNextDeck(DailySession session) {
    return session.deck.expiresAt.difference(_now());
  }

  /// Takes unread facts first. Read ones fill any gap, starting from a point
  /// that moves each day, so repeated cards change between days.
  List<String> _chooseFactIds(List<Fact> facts) {
    final unread = facts.where((fact) => !fact.isRead).toList();
    final read = facts.where((fact) => fact.isRead).toList();

    final today = _now();
    final dayNumber = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(1970)).inDays;
    final start = read.isEmpty ? 0 : dayNumber % read.length;

    return [
      ...unread,
      ...read.skip(start),
      ...read.take(start),
    ].take(deckSize).map((fact) => fact.id).toList();
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
