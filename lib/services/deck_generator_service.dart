import 'dart:math';

import 'package:dziesiatka/models/fact.dart';
import 'package:flutter/foundation.dart';

/// Chooses the cards of a daily deck: mostly the user's favorite categories,
/// [discoveryCount] from the others to keep the deck varied, and one review.
class DeckGeneratorService {
  const DeckGeneratorService({required this.now, this.log = debugLog});

  /// Says in debug builds why a partner card did or did not go in. Release
  /// builds print nothing.
  static void debugLog(String message) {
    if (kDebugMode) debugPrint('[Dziesiątka] $message');
  }

  static const deckSize = 10;
  static const discoveryCount = 2;
  static const maxReviewCount = 1;
  static const minDaysBetweenReads = 3;
  static const maxSameCategoryInRow = 2;

  /// Partner offers stay a small extra: one per deck and one per bonus round.
  static const maxOffersPerRound = 1;

  /// The most that 3 other cards can still keep apart with no 3 in a row.
  static const maxSameCategoryInDeck = 7;

  final DateTime Function() now;
  final void Function(String message) log;

  /// Takes the review first, as it is the only card that needs a due fact.
  /// Without one its place goes to a favorite. New facts fill any gap before
  /// read ones do, so the deck stays full and repeats only when it must.
  ///
  /// Partner facts in [allFacts] never take one of these places. One of them
  /// can come on top of the deck, see [withPartner].
  List<Fact> generate(
    List<Fact> allFacts, {
    required Set<String> disabledCategories,
    required Random random,
  }) {
    bool isFavorite(Fact fact) => !disabledCategories.contains(fact.category);
    final facts = allFacts.where((fact) => !fact.isPartner).toList();

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
    final spares = [...unread, ...read].where((fact) => !chosen.contains(fact));
    return withPartner(
      chosen,
      spares,
      partners: allFacts,
      random: random,
      arrange: _withoutLongRuns,
    );
  }

  /// Limits offers in [cards] and adds one partner fact when it can. The
  /// partner card counts as the round's one offer, so a card with an offer
  /// first gives its place to one from [spares]. If none can, the partner
  /// card waits for another day.
  ///
  /// [partners] may hold any facts: only unread partner facts still in
  /// circulation and with an active offer are taken. [arrange] orders the
  /// cards before the partner card goes in, never first and never last, so
  /// it takes no category's place and breaks no run.
  List<Fact> withPartner(
    List<Fact> cards,
    Iterable<Fact> spares, {
    required Iterable<Fact> partners,
    required Random random,
    List<Fact> Function(List<Fact>) arrange = _keepOrder,
  }) {
    final moment = now();
    if (cards.length < 2) {
      log(
        'Karta partnerska pominięta: runda ma ${cards.length} kart, a '
        'karta partnerska musi stać między dwiema.',
      );
      return arrange(limitOffers(cards, spares));
    }
    final partner = pickPartner(partners, random);
    if (partner == null) return arrange(limitOffers(cards, spares));

    final withoutOffers = limitOffers(cards, spares, maxOffers: 0);
    if (withoutOffers.any((fact) => fact.activeOfferOn(moment) != null)) {
      log(
        'Karta partnerska ${partner.id} pominięta: w rundzie zostaje karta '
        'z poleceniem, której nie da się wymienić.',
      );
      return arrange(limitOffers(cards, spares));
    }

    final arranged = arrange(withoutOffers);
    final position = 1 + random.nextInt(arranged.length - 1);
    log(
      'Karta partnerska ${partner.id} wstawiona na pozycję ${position + 1} '
      'z ${arranged.length + 1}.',
    );
    return [...arranged]..insert(position, partner);
  }

  /// One unread partner fact still in circulation and with an active offer,
  /// or null with the reason in [log].
  Fact? pickPartner(Iterable<Fact> partners, Random random) {
    final moment = now();
    final all = partners.where((fact) => fact.isPartner).toList();
    final candidates = all
        .where(
          (fact) => !fact.isRead && !fact.isWithdrawn && fact.isShownOn(moment),
        )
        .toList();
    if (candidates.isEmpty) {
      log(
        all.isEmpty
            ? 'Karta partnerska pominięta: brak kart partnerskich na '
                  'urządzeniu. Pobierają się w tle, po wyborze talii.'
            : 'Karta partnerska pominięta: z ${all.length} kart '
                  '${all.where((fact) => fact.isRead).length} przeczytane, '
                  '${all.where((fact) => fact.isWithdrawn).length} wycofane, '
                  '${all.where((fact) => !fact.isShownOn(moment)).length} '
                  'po terminie.',
      );
      return null;
    }
    return candidates[random.nextInt(candidates.length)];
  }

  static List<Fact> _keepOrder(List<Fact> cards) => cards;

  /// Keeps the first [maxOffers] cards with an active offer. Each one past
  /// that gives its place to a card without an offer from [spares], from the
  /// same category and in the same read state when there is one, so the mix
  /// of favorites, discoveries and reviews stays as chosen. A card that has
  /// no fitting replacement stays, because a full deck matters more. Partner
  /// facts in [spares] are never used.
  List<Fact> limitOffers(
    List<Fact> cards,
    Iterable<Fact> spares, {
    int maxOffers = maxOffersPerRound,
  }) {
    final moment = now();
    bool hasOffer(Fact fact) => fact.activeOfferOn(moment) != null;

    final free = spares
        .where((fact) => !hasOffer(fact) && !fact.isPartner)
        .toList();
    final result = <Fact>[];
    var offers = 0;
    for (final (index, card) in cards.indexed) {
      if (!hasOffer(card) || offers < maxOffers) {
        if (hasOffer(card)) offers++;
        result.add(card);
        continue;
      }

      final others = [...result, ...cards.skip(index + 1)];
      final replacement = _replacementFor(card, free, others);
      if (replacement == null) {
        offers++;
        result.add(card);
      } else {
        free.remove(replacement);
        result.add(replacement);
      }
    }
    return result;
  }

  /// [others] are the rest of the deck, without [card].
  Fact? _replacementFor(Fact card, List<Fact> free, List<Fact> others) {
    bool fitsCategory(Fact fact) {
      if (fact.category == card.category) return true;
      final count = others.where((item) => item.category == fact.category);
      return count.length < maxSameCategoryInDeck;
    }

    final rules = <bool Function(Fact)>[
      (fact) => fact.category == card.category && fact.isRead == card.isRead,
      (fact) => fact.category == card.category,
      (fact) => fact.isRead == card.isRead && fitsCategory(fact),
      fitsCategory,
    ];
    for (final rule in rules) {
      for (final fact in free) {
        if (rule(fact)) return fact;
      }
    }
    return null;
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
