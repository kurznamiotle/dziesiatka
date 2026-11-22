import 'package:dziesiatka/models/fact_offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const offer = FactOffer(
    product: 'Atlas nieba',
    shop: 'Księgarnia',
    url: 'https://example.com/atlas',
    until: '2026-11-30',
  );

  test('round-trips through JSON', () {
    expect(FactOffer.tryParse(offer.toJson()), offer);
  });

  test('a missing end date is left out of JSON', () {
    const open = FactOffer(product: 'A', shop: 'B', url: 'https://a.pl');

    expect(open.toJson().containsKey('until'), isFalse);
    expect(FactOffer.tryParse(open.toJson()), open);
  });

  test('a wrong shape reads as no offer', () {
    expect(FactOffer.tryParse(null), isNull);
    expect(FactOffer.tryParse('oferta'), isNull);
    expect(FactOffer.tryParse({'product': 'A', 'shop': 'B'}), isNull);
    expect(
      FactOffer.tryParse({'product': 1, 'shop': 'B', 'url': 'https://a.pl'}),
      isNull,
    );
  });

  group('isActiveOn', () {
    test('lasts through the whole last day', () {
      expect(offer.isActiveOn(DateTime(2026, 11, 30, 23, 59)), isTrue);
      expect(offer.isActiveOn(DateTime(2026, 12, 1)), isFalse);
    });

    test('has no end without a date', () {
      const open = FactOffer(product: 'A', shop: 'B', url: 'https://a.pl');

      expect(open.isActiveOn(DateTime(2099)), isTrue);
    });

    test('a wrong date counts as ended', () {
      const broken = FactOffer(
        product: 'A',
        shop: 'B',
        url: 'https://a.pl',
        until: '2026-02-30',
      );

      expect(broken.isActiveOn(DateTime(2026)), isFalse);
    });
  });

  group('validationErrors', () {
    test('accepts a valid offer', () {
      expect(offer.validationErrors(), isEmpty);
    });

    test('follows the database limits', () {
      final errors = FactOffer(
        product: 'x' * 81,
        shop: ' ',
        url: 'http://example.com',
        until: '30.11.2026',
      ).validationErrors();

      expect(errors, hasLength(4));
    });

    test('accepts the longest names', () {
      final longest = FactOffer(
        product: 'x' * FactOffer.maxProductLength,
        shop: 'y' * FactOffer.maxShopLength,
        url: 'https://example.com',
      );

      expect(longest.validationErrors(), isEmpty);
    });
  });
}
