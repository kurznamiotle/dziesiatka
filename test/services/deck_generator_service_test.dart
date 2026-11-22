import 'dart:math';

import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/services/deck_generator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 10, 12);
  final generator = DeckGeneratorService(now: () => now);
  var nextId = 0;

  Fact fact(String category, {DateTime? lastReadAt, bool isRead = false}) {
    return Fact(
      id: 'fact-${nextId++}',
      title: 'Fakt',
      category: category,
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      sourceLabel: 'Źródło',
      isRead: isRead || lastReadAt != null,
      lastReadAt: lastReadAt,
      createdAt: DateTime.utc(2026),
    );
  }

  List<Fact> many(int count, String category) {
    return [for (var i = 0; i < count; i++) fact(category)];
  }

  List<Fact> generate(
    List<Fact> facts, {
    Set<String> disabled = const {},
    int seed = 1,
  }) {
    return generator.generate(
      facts,
      disabledCategories: disabled,
      random: Random(seed),
    );
  }

  int countIn(List<Fact> deck, Set<String> categories) {
    return deck.where((card) => categories.contains(card.category)).length;
  }

  int longestRun(List<Fact> deck) {
    var longest = 0;
    var run = 0;
    String? last;
    for (final card in deck) {
      run = card.category == last ? run + 1 : 1;
      last = card.category;
      longest = max(longest, run);
    }
    return longest;
  }

  const favorites = {'Kosmos', 'Historia', 'Technologia'};
  const others = {'Psychologia', 'Zwierzęta'};

  List<Fact> balancedPool() {
    return [
      for (final category in [...favorites, ...others]) ...many(20, category),
    ];
  }

  test('7 favorites, 2 discoveries and 1 review', () {
    final review = fact('Kosmos', lastReadAt: DateTime(2026, 11, 7));

    final deck = generate([...balancedPool(), review], disabled: others);

    expect(deck, hasLength(10));
    expect(deck, contains(review));
    expect(countIn(deck, others), 2);
    expect(countIn(deck, favorites), 8);
  });

  test('a review from a discovery category does not cost a discovery', () {
    final review = fact('Zwierzęta', lastReadAt: DateTime(2026, 11, 7));

    final deck = generate([...balancedPool(), review], disabled: others);

    expect(deck, contains(review));
    expect(countIn(deck, others), 3);
    expect(countIn(deck, favorites), 7);
  });

  test('without a due review it is 8 favorites and 2 discoveries', () {
    final recent = fact('Kosmos', lastReadAt: DateTime(2026, 11, 8));

    final deck = generate([...balancedPool(), recent], disabled: others);

    expect(deck, isNot(contains(recent)));
    expect(countIn(deck, favorites), 8);
    expect(countIn(deck, others), 2);
  });

  test('with all categories on, the whole pool is in rotation', () {
    final decks = [
      for (var seed = 0; seed < 20; seed++)
        generate(balancedPool(), seed: seed),
    ];

    for (final deck in decks) {
      expect(deck, hasLength(10));
    }
    final seen = decks.expand((deck) => deck).map((card) => card.category);
    expect(seen.toSet(), {...favorites, ...others});
  });

  test('new discoveries fill in when favorites run out', () {
    final deck = generate([
      ...many(4, 'Kosmos'),
      ...many(20, 'Zwierzęta'),
    ], disabled: others);

    expect(deck, hasLength(10));
    expect(countIn(deck, {'Kosmos'}), 4);
  });

  test('a new fact comes before a repeat', () {
    final read = fact('Kosmos', isRead: true);
    final unread = many(10, 'Zwierzęta');

    final deck = generate([...unread, read], disabled: others);

    expect(deck, hasLength(10));
    expect(deck.first.isRead || deck.any((card) => card.isRead), isTrue);
    expect(deck.where((card) => !card.isRead), hasLength(9));
  });

  test('read facts fill a deck that would stay short', () {
    final deck = generate([
      for (var i = 0; i < 12; i++)
        fact('Kosmos', lastReadAt: DateTime(2026, 11, 9)),
    ]);

    expect(deck, hasLength(10));
  });

  test('no more than 2 cards of a category in a row', () {
    for (var seed = 0; seed < 300; seed++) {
      final deck = generate(balancedPool(), disabled: others, seed: seed);

      expect(longestRun(deck), lessThanOrEqualTo(2), reason: 'ziarno $seed');
    }
  });

  test('an uneven deck still spreads when it is possible', () {
    for (var seed = 0; seed < 300; seed++) {
      final deck = generate(
        [
          ...many(30, 'Kosmos'),
          ...many(3, 'Historia'),
          ...many(30, 'Psychologia'),
        ],
        disabled: {'Psychologia'},
        seed: seed,
      );

      expect(countIn(deck, {'Kosmos'}), greaterThan(4));
      expect(longestRun(deck), lessThanOrEqualTo(2), reason: 'ziarno $seed');
    }
  });

  test('the same seed gives the same deck', () {
    final pool = balancedPool();

    expect(
      generate(pool, disabled: others, seed: 7).map((card) => card.id),
      generate(pool, disabled: others, seed: 7).map((card) => card.id),
    );
  });

  test('a single category cannot be spread but still fills the deck', () {
    expect(generate(many(20, 'Kosmos')), hasLength(10));
  });

  group('partner offers', () {
    const offer = FactOffer(
      product: 'Atlas nieba',
      shop: 'Księgarnia',
      url: 'https://example.com/atlas',
    );

    Fact withOffer(Fact fact, {String? until}) {
      return fact.copyWith(
        offer: FactOffer(
          product: offer.product,
          shop: offer.shop,
          url: offer.url,
          until: until,
        ),
      );
    }

    int offersIn(List<Fact> deck) {
      return deck.where((card) => card.activeOfferOn(now) != null).length;
    }

    test('a deck has at most one card with an offer', () {
      for (var seed = 0; seed < 30; seed++) {
        final pool = [
          for (final fact in balancedPool()) withOffer(fact),
          ...balancedPool(),
        ];
        final deck = generate(pool, disabled: others, seed: seed);

        expect(deck, hasLength(10), reason: 'seed $seed');
        expect(offersIn(deck), 1, reason: 'seed $seed');
      }
    });

    test('keeps 7-2-1 and short runs while replacing offers', () {
      for (var seed = 0; seed < 30; seed++) {
        final review = fact('Kosmos', lastReadAt: DateTime(2026, 11, 7));
        final pool = [
          for (final (index, fact) in balancedPool().indexed)
            index.isEven ? withOffer(fact) : fact,
          review,
        ];
        final deck = generate(pool, disabled: others, seed: seed);

        expect(offersIn(deck), lessThanOrEqualTo(1), reason: 'seed $seed');
        expect(countIn(deck, others), 2, reason: 'seed $seed');
        expect(deck.where((card) => card.isRead), hasLength(1));
        expect(longestRun(deck), lessThanOrEqualTo(2), reason: 'seed $seed');
      }
    });

    test('an ended offer does not count', () {
      final pool = [
        for (final fact in balancedPool()) withOffer(fact, until: '2026-11-09'),
      ];

      final deck = generate(pool, disabled: others);

      expect(deck.where((card) => card.offer != null), hasLength(10));
      expect(offersIn(deck), 0);
    });

    test('the category limit can leave an extra offer in', () {
      final pool = [
        for (final fact in balancedPool()) withOffer(fact),
        ...many(30, 'Kosmos'),
      ];

      final deck = generate(pool, disabled: others);

      expect(deck, hasLength(10));
      expect(countIn(deck, {'Kosmos'}), lessThanOrEqualTo(7));
    });

    test('a card stays when nothing can replace it', () {
      final pool = [for (final fact in many(10, 'Kosmos')) withOffer(fact)];

      final deck = generate(pool);

      expect(deck, hasLength(10));
    });

    test('limitOffers prefers a replacement from the same category', () {
      final cards = [
        withOffer(fact('Kosmos')),
        withOffer(fact('Historia')),
        fact('Technologia'),
      ];
      final spare = fact('Historia');

      final limited = generator.limitOffers(cards, [
        withOffer(fact('Historia')),
        fact('Zwierzęta'),
        spare,
      ]);

      expect(limited, [cards[0], spare, cards[2]]);
    });
  });
}
