import 'dart:convert';
import 'dart:math';

import 'package:dziesiatka/models/completed_card.dart';
import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/models/daily_session.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/services/category_preferences_service.dart';
import 'package:dziesiatka/services/deck_generator_service.dart';
import 'package:dziesiatka/services/facts_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyDeckService {
  DailyDeckService(
    this._factsService,
    this._streakService, {
    DateTime Function()? now,
    Random? random,
    CategoryPreferencesService categoryPreferences =
        const CategoryPreferencesService(),
  }) : _now = now ?? DateTime.now,
       _random = random,
       _categoryPreferences = categoryPreferences,
       _generator = DeckGeneratorService(now: now ?? DateTime.now);

  static const deckSize = DeckGeneratorService.deckSize;
  static const bonusSize = 5;
  static const quizQuestionCount = 4;
  static const _deckKey = 'dailyDeck';
  static const _ownerIdKey = 'deckOwnerId';

  /// Keeps the hash within what both the VM and the web can multiply exactly.
  static const _hashModulus = 1000000007;

  /// Not written as a shift, because `1 << 32` gives 0 on the web.
  static const _ownerIdLimit = 0x100000000;

  final FactsService _factsService;
  final StreakService _streakService;
  final DateTime Function() _now;
  final Random? _random;
  final CategoryPreferencesService _categoryPreferences;
  final DeckGeneratorService _generator;

  /// Returns today's deck, choosing and saving a new one on the first call of
  /// each day, so the cards stay the same across restarts.
  Future<DailySession> loadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final facts = await _factsService.getFacts();
    final streak = await _streakService.getCurrentStreak();
    final today = DailyDeck.dateKey(_now());
    final factIds = facts.map((fact) => fact.id).toSet();

    final disabled = await _categoryPreferences.getDisabled();

    DailySession sessionOf(DailyDeck deck) {
      return DailySession(
        deck: deck,
        pool: facts,
        streak: streak,
        bonusCount: min(_bonusFacts(facts, deck, disabled).length, bonusSize),
      );
    }

    final stored = _readDeck(prefs);
    if (stored != null &&
        stored.date == today &&
        stored.factIds.every(factIds.contains)) {
      return sessionOf(stored);
    }

    final random = await _randomFor(prefs, today);
    final chosen = _generator.generate(
      facts.where((fact) => !fact.isWithdrawn).toList(),
      disabledCategories: disabled,
      random: random,
    );
    final deck = DailyDeck(
      date: today,
      factIds: chosen.map((fact) => fact.id).toList(),
      quizFactIds: _chooseQuizFactIds(chosen, random),
      reviewFactIds: chosen
          .where((fact) => fact.isRead)
          .map((fact) => fact.id)
          .toList(),
    );
    await _saveDeck(prefs, deck);
    return sessionOf(deck);
  }

  /// Adds a round of unread cards after the day is finished. They are optional,
  /// so they count toward neither the quiz nor the streak.
  Future<DailySession> addBonusCards() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await loadToday();
    if (!session.isDayFinished || session.remaining.isNotEmpty) return session;

    final bonus = _bonusFacts(
      await _factsService.getFacts(),
      session.deck,
      await _categoryPreferences.getDisabled(),
    );
    bonus.shuffle(
      await _randomFor(
        prefs,
        '${session.deck.date}:bonus:${session.deck.factIds.length}',
      ),
    );
    await _saveDeck(
      prefs,
      session.deck.withBonus(
        bonus.take(bonusSize).map((fact) => fact.id).toList(),
      ),
    );
    return loadToday();
  }

  List<Fact> _bonusFacts(
    List<Fact> facts,
    DailyDeck deck,
    Set<String> disabledCategories,
  ) {
    return facts
        .where((fact) => !fact.isRead && !fact.isWithdrawn)
        .where((fact) => !disabledCategories.contains(fact.category))
        .where((fact) => !deck.factIds.contains(fact.id))
        .toList();
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
      lastReadAt: _now(),
    );
    await _saveDeck(
      prefs,
      session.deck.withCompleted(
        CompletedCard(
          factId: factId,
          wasRead: fact.isRead,
          wasFavorite: fact.isFavorite,
          previousLastReadAt: fact.lastReadAt,
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
      lastReadAt: last.previousLastReadAt,
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

  /// Depends only on [salt] and this user's id, so a lost deck comes back the
  /// same on the same day. The id never leaves the device.
  Future<Random> _randomFor(SharedPreferences prefs, String salt) async {
    final fixed = _random;
    if (fixed != null) return fixed;

    var ownerId = prefs.getString(_ownerIdKey);
    if (ownerId == null) {
      ownerId = Random.secure().nextInt(_ownerIdLimit).toRadixString(16);
      await prefs.setString(_ownerIdKey, ownerId);
    }
    return Random(_stableHash('$salt:$ownerId'));
  }

  /// [String.hashCode] may change between runs, so it cannot seed a repeatable
  /// choice.
  int _stableHash(String text) {
    return text.codeUnits.fold(
      0,
      (hash, unit) => (hash * 31 + unit) % _hashModulus,
    );
  }

  List<String> _chooseQuizFactIds(List<Fact> deckFacts, Random random) {
    final withQuestions = deckFacts.where((fact) => fact.quiz != null).toList()
      ..shuffle(random);
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
