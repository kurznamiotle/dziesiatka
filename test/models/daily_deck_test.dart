import 'package:dziesiatka/models/completed_card.dart';
import 'package:dziesiatka/models/daily_deck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const card = CompletedCard(factId: 'b', wasRead: true, wasFavorite: false);
  const deck = DailyDeck(
    date: '2026-03-09',
    factIds: ['a', 'b', 'c'],
    reviewFactIds: ['c'],
    completed: [card],
  );

  test('a completed card keeps its previous read date', () {
    final completed = CompletedCard(
      factId: 'a',
      wasRead: true,
      wasFavorite: false,
      previousLastReadAt: DateTime.utc(2026, 3, 9),
    );

    final restored = CompletedCard.fromJson(completed.toJson());

    expect(restored.previousLastReadAt, completed.previousLastReadAt);
  });

  test('a deck saved before reviews were marked still loads', () {
    final json = deck.toJson()..remove('reviewFactIds');

    expect(DailyDeck.fromJson(json).reviewFactIds, isEmpty);
  });

  test('dateKey pads the month and day', () {
    expect(DailyDeck.dateKey(DateTime(2026, 3, 9, 23, 59)), '2026-03-09');
  });

  test('toJson and fromJson round-trip the deck', () {
    final restored = DailyDeck.fromJson(deck.toJson());

    expect(restored.date, deck.date);
    expect(restored.factIds, deck.factIds);
    expect(restored.reviewFactIds, deck.reviewFactIds);
    expect(restored.completed.single.factId, card.factId);
    expect(restored.completed.single.wasRead, card.wasRead);
    expect(restored.completed.single.wasFavorite, card.wasFavorite);
  });

  test('remainingIds keeps deck order without completed cards', () {
    expect(deck.remainingIds, ['a', 'c']);
  });

  test('withCompleted and withoutLastCompleted are opposites', () {
    const next = CompletedCard(factId: 'a', wasRead: false, wasFavorite: false);

    final completed = deck.withCompleted(next);
    expect(completed.remainingIds, ['c']);

    expect(completed.withoutLastCompleted().remainingIds, ['a', 'c']);
  });

  test('expiresAt is the next local midnight', () {
    expect(
      const DailyDeck(date: '2026-12-31', factIds: []).expiresAt,
      DateTime(2027),
    );
  });
}
