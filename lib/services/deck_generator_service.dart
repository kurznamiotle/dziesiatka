import 'dart:math';

import 'package:dziesiatka/models/fact.dart';

/// Chooses the cards of a daily deck: mostly the user's favorite categories,
/// [discoveryCount] from the others to keep the deck varied, and one review.
class DeckGeneratorService {
  const DeckGeneratorService({required this.now});

  static const deckSize = 10;
  static const discoveryCount = 2;
  static const maxReviewCount = 1;
  static const minDaysBetweenReads = 3;
  static const maxSameCategoryInRow = 2;

  /// The most that 3 other cards can still keep apart with no 3 in a row.
  static const maxSameCategoryInDeck = 7;

  final DateTime Function() now;

  /// Takes the review first, as it is the only card that needs a due fact.
  /// Without one its place goes to a favorite. New facts fill any gap before
  /// read ones do, so the deck stays full and repeats only when it must.
  List<Fact> generate(
    List<Fact> facts, {
    required Set<String> disabledCategories,
    required Random random,
  }) {
    bool isFavorite(Fact fact) => !disabledCategories.contains(fact.category);

    final unread = facts.where((fact) => !fact.isRead).toList()
      ..shuffle(random);
    final read = facts.where((fact) => fact.isRead).toList()
      ..sort(_compareByLastRead);

    final due = read.where(_isDueForReview).toList()..shuffle(random);
    final reviews = due.take(maxReviewCount).toList();
    final discoveries = unread
        .where((fact) => !isFavorite(fact))
        .take(discoveryCount)
        .toList();
    final favorites = _takeWithinLimit(
      unread.where(isFavorite),
      deckSize - reviews.length - discoveries.length,
      alreadyChosen: [...reviews, ...discoveries],
    );

    final rest = <Fact>{
      ...favorites,
      ...discoveries,
      ...unread,
      ...read.where(isFavorite),
      ...read,
    }.difference(reviews.toSet());
    final chosen = [...rest.take(deckSize - reviews.length), ...reviews]
      ..shuffle(random);
    return _withoutLongRuns(chosen);
  }

  /// Walks the shuffled cards and skips ahead only when the next card would
  /// extend a run too far or leave the rest impossible to spread. If a category
  /// holds too many cards to spread at all, its runs stay as short as they can.
  List<Fact> _withoutLongRuns(List<Fact> cards) {
    final pool = [...cards];
    final result = <Fact>[];
    while (pool.isNotEmpty) {
      final next = pool.firstWhere(
        (card) => _keepsRunsShort(card, result, pool),
        orElse: () => _leastHarmful(result, pool),
      );
      pool.remove(next);
      result.add(next);
    }
    return result;
  }

  /// With no way to keep runs short, uses up the largest category first, so
  /// the long run stays as short as the cards allow.
  Fact _leastHarmful(List<Fact> result, List<Fact> pool) {
    int left(Fact card) {
      return pool.where((fact) => fact.category == card.category).length;
    }

    final allowed = pool.where(
      (card) => _runAfter(card, result) <= maxSameCategoryInRow,
    );
    return (allowed.isEmpty ? pool : allowed).reduce(
      (best, card) => left(card) > left(best) ? card : best,
    );
  }

  List<Fact> _takeWithinLimit(
    Iterable<Fact> pool,
    int count, {
    required List<Fact> alreadyChosen,
  }) {
    final counts = <String, int>{};
    for (final fact in alreadyChosen) {
      counts.update(fact.category, (count) => count + 1, ifAbsent: () => 1);
    }

    final taken = <Fact>[];
    for (final fact in pool) {
      if (taken.length == count) break;
      if ((counts[fact.category] ?? 0) >= maxSameCategoryInDeck) continue;
      counts.update(fact.category, (count) => count + 1, ifAbsent: () => 1);
      taken.add(fact);
    }
    return taken;
  }

  int _runAfter(Fact card, List<Fact> result) {
    final before = result.reversed.takeWhile(
      (fact) => fact.category == card.category,
    );
    return before.length + 1;
  }

  /// Checks that the cards left after [card] still fit: the others separate a
  /// category into groups, and the group that continues [card]'s run has less
  /// room than the rest.
  bool _keepsRunsShort(Fact card, List<Fact> result, List<Fact> pool) {
    final run = _runAfter(card, result);
    if (run > maxSameCategoryInRow) return false;

    final left = [...pool]..remove(card);
    final counts = <String, int>{};
    for (final fact in left) {
      counts.update(fact.category, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts.entries.every((entry) {
      final separators = left.length - entry.value;
      final firstGroup =
          maxSameCategoryInRow - (entry.key == card.category ? run : 0);
      return entry.value <= separators * maxSameCategoryInRow + firstGroup;
    });
  }

  int _dayNumberOf(DateTime moment) {
    final local = moment.toLocal();
    final day = DateTime.utc(local.year, local.month, local.day);
    return day.difference(DateTime.utc(1970)).inDays;
  }

  /// Counts calendar days, so a card read late in the evening comes back on
  /// the same day as one read that morning.
  bool _isDueForReview(Fact fact) {
    final lastReadAt = fact.lastReadAt;
    if (lastReadAt == null) return true;
    return _dayNumberOf(now()) - _dayNumberOf(lastReadAt) >=
        minDaysBetweenReads;
  }

  /// Puts facts read longest ago first. Those read before dates were saved
  /// have none and count as the oldest.
  int _compareByLastRead(Fact first, Fact second) {
    final firstRead = first.lastReadAt;
    final secondRead = second.lastReadAt;
    if (firstRead == null) return secondRead == null ? 0 : -1;
    if (secondRead == null) return 1;
    return firstRead.compareTo(secondRead);
  }
}
