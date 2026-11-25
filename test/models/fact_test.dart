import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/fact_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fact = Fact(
    id: '1',
    title: 'Tytuł',
    category: 'Kosmos',
    shortText: 'Zajawka',
    longText: 'Rozwinięcie',
    sourceLabel: 'Przykład',
    sourceUrl: 'https://example.com',
    isWithdrawn: true,
    isRead: true,
    isFavorite: true,
    lastReadAt: DateTime.utc(2026, 2, 3, 4, 5, 6),
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    updatedAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
  );

  void expectSameContent(Fact actual, Fact expected) {
    expect(actual.id, expected.id);
    expect(actual.title, expected.title);
    expect(actual.category, expected.category);
    expect(actual.shortText, expected.shortText);
    expect(actual.longText, expected.longText);
    expect(actual.sourceLabel, expected.sourceLabel);
    expect(actual.sourceUrl, expected.sourceUrl);
    expect(actual.isWithdrawn, expected.isWithdrawn);
    expect(actual.createdAt, expected.createdAt);
    expect(actual.updatedAt, expected.updatedAt);
  }

  test('toJson and fromJson round-trip the content', () {
    expectSameContent(Fact.fromJson(fact.toJson()), fact);
  });

  test('toJson leaves out the user\'s state', () {
    final json = fact.toJson();

    expect(json.containsKey('isRead'), isFalse);
    expect(json.containsKey('isFavorite'), isFalse);
    expect(json.containsKey('lastReadAt'), isFalse);
  });

  test('state round-trips through JSON', () {
    final restored = FactState.fromJson(fact.state.toJson());

    expect(restored.isRead, isTrue);
    expect(restored.isFavorite, isTrue);
    expect(restored.lastReadAt, fact.lastReadAt);
  });

  test('updatedAt falls back to createdAt', () {
    final json = fact.toJson()..remove('updatedAt');

    expect(Fact.fromJson(json).updatedAt, fact.createdAt);
  });

  test('copyWith changes only the given fields', () {
    final copy = fact.copyWith(shortText: 'Inna', isRead: false);

    expect(copy.shortText, 'Inna');
    expect(copy.isRead, isFalse);
    expect(copy.isFavorite, isTrue);
    expectSameContent(copy.copyWith(shortText: 'Zajawka'), fact);
  });

  test('withState replaces the state and can clear the read date', () {
    final cleared = fact.withState(const FactState());

    expect(cleared.isRead, isFalse);
    expect(cleared.isFavorite, isFalse);
    expect(cleared.lastReadAt, isNull);
    expect(cleared.title, fact.title);
  });

  test('a default state is recognized', () {
    expect(const FactState().isDefault, isTrue);
    expect(const FactState(isFavorite: true).isDefault, isFalse);
  });

  test('fromJson reads facts saved with the old content field', () {
    final restored = Fact.fromJson({
      'id': 'old',
      'title': 'Stary fakt',
      'content': 'Treść',
      'category': 'Historia',
      'isRead': true,
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    expect(restored.shortText, 'Treść');
    expect(restored.longText, 'Treść');
    expect(restored.sourceLabel, isEmpty);
    expect(restored.sourceUrl, isNull);
  });

  test('fromJson reads facts saved with the old source field', () {
    final restored = Fact.fromJson({
      'id': 'old',
      'title': 'Stary fakt',
      'category': 'Historia',
      'shortText': 'Zajawka',
      'longText': 'Rozwinięcie',
      'source': 'Encyklopedia',
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    expect(restored.sourceLabel, 'Encyklopedia');
  });

  group('offer', () {
    const offer = FactOffer(
      product: 'Atlas nieba',
      shop: 'Księgarnia',
      url: 'https://example.com/atlas',
      until: '2026-11-30',
    );

    Map<String, dynamic> row({Object? offer, bool withOffer = true}) {
      return {
        'id': 'fact-1',
        'title': 'Tytuł',
        'category': 'Kosmos',
        'short_text': 'Zajawka',
        'long_text': 'Rozwinięcie',
        'source_label': 'NASA',
        'source_url': null,
        'status': 'published',
        'quiz': null,
        if (withOffer) 'offer': offer,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
    }

    test('round-trips through JSON', () {
      final restored = Fact.fromJson(fact.copyWith(offer: offer).toJson());

      expect(restored.offer, offer);
    });

    test('is read from a database row', () {
      expect(Fact.fromRow(row(offer: offer.toJson())).offer, offer);
    });

    test('a row from before the migration has none', () {
      expect(Fact.fromRow(row(withOffer: false)).offer, isNull);
    });

    test('facts saved before offers have none', () {
      final json = fact.toJson()..remove('offer');

      expect(Fact.fromJson(json).offer, isNull);
    });

    test('ends after its last day', () {
      final withOffer = fact.copyWith(offer: offer);

      expect(withOffer.activeOfferOn(DateTime(2026, 11, 30, 20)), offer);
      expect(withOffer.activeOfferOn(DateTime(2026, 12, 1, 8)), isNull);
    });

    test('survives a change of state', () {
      final withOffer = fact.copyWith(offer: offer);

      expect(withOffer.withState(const FactState()).offer, offer);
    });
  });

  group('kind', () {
    final row = {
      'id': 'fact-1',
      'title': 'Tytuł',
      'category': 'Kosmos',
      'short_text': 'Zajawka',
      'long_text': 'Rozwinięcie',
      'source_label': 'NASA',
      'source_url': null,
      'status': 'published',
      'created_at': '2026-11-01T00:00:00Z',
      'updated_at': '2026-11-01T00:00:00Z',
    };
    const offer = FactOffer(
      product: 'Atlas nieba',
      shop: 'Księgarnia',
      url: 'https://example.com/atlas',
      until: '2026-11-30',
    );

    test('a row without kind is regular', () {
      expect(Fact.fromRow(row).kind, FactKind.regular);
      expect(Fact.fromRow(row).isPartner, isFalse);
    });

    test('a partner row is a partner fact', () {
      final fact = Fact.fromRow({
        ...row,
        'kind': 'partner',
        'category': FactKind.partnerCategory,
        'offer': offer.toJson(),
      });

      expect(fact.isPartner, isTrue);
      expect(fact.offer, offer);
    });

    test('an unknown kind is regular', () {
      expect(Fact.fromRow({...row, 'kind': 'inny'}).kind, FactKind.regular);
    });

    test('kind round-trips through JSON', () {
      final partner = fact.copyWith(kind: FactKind.partner);

      expect(Fact.fromJson(partner.toJson()).kind, FactKind.partner);
      expect(Fact.fromJson(fact.toJson()).kind, FactKind.regular);
    });

    test('a partner fact saved without kind is still a partner', () {
      final json = fact.copyWith(category: FactKind.partnerCategory).toJson()
        ..remove('kind');

      expect(Fact.fromJson(json).kind, FactKind.partner);
    });

    test('withState keeps the kind', () {
      final partner = fact.copyWith(kind: FactKind.partner);

      expect(partner.withState(const FactState()).kind, FactKind.partner);
    });

    test('a partner fact is shown only while its offer lasts', () {
      final partner = fact.copyWith(kind: FactKind.partner, offer: offer);
      final withoutOffer = fact.copyWith(kind: FactKind.partner);

      expect(partner.isShownOn(DateTime(2026, 11, 30, 23)), isTrue);
      expect(partner.isShownOn(DateTime(2026, 12, 1)), isFalse);
      expect(withoutOffer.isShownOn(DateTime(2026)), isFalse);
      expect(fact.isShownOn(DateTime(2030)), isTrue);
    });
  });
}
