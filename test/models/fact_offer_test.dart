import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/offer_status.dart';
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

  group('status', () {
    test('an offer without an end is active', () {
      const open = FactOffer(product: 'A', shop: 'B', url: 'https://a.pl');

      expect(open.statusOn(DateTime(2030)), OfferStatus.active);
    });

    test('the last 7 days are ending soon', () {
      expect(offer.statusOn(DateTime(2026, 11, 22)), OfferStatus.active);
      expect(offer.statusOn(DateTime(2026, 11, 23)), OfferStatus.endingSoon);
      expect(
        offer.statusOn(DateTime(2026, 11, 30, 23)),
        OfferStatus.endingSoon,
      );
      expect(offer.statusOn(DateTime(2026, 12, 1)), OfferStatus.ended);
    });
  });

  group('extendedOn', () {
    test('adds 30 days to the current end', () {
      expect(offer.extendedOn(DateTime(2026, 11, 25)).until, '2026-12-30');
    });

    test('an ended offer runs 30 days from today', () {
      expect(offer.extendedOn(DateTime(2027, 1, 10)).until, '2027-02-09');
    });

    test('an offer without an end stays without one', () {
      const open = FactOffer(product: 'A', shop: 'B', url: 'https://a.pl');

      expect(open.extendedOn(DateTime(2026)), open);
    });

    test('keeps the product, shop and link', () {
      final extended = offer.extendedOn(DateTime(2026, 11, 25));

      expect(extended.product, offer.product);
      expect(extended.shop, offer.shop);
      expect(extended.url, offer.url);
    });
  });
}
