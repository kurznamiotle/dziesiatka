import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/fact_usage.dart';
import 'package:dziesiatka/models/offer_status.dart';
import 'package:dziesiatka/services/admin_offers_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AdminOffersService();
  final now = DateTime(2026, 11, 25, 12);

  FactOffer offer({String? until}) {
    return FactOffer(
      product: 'Atlas',
      shop: 'Sklep',
      url: 'https://example.com',
      until: until,
    );
  }

  AdminFact regular(
    String id, {
    FactOffer? offer,
    String status = AdminFact.published,
    String title = 'Fakt',
  }) {
    return AdminFact(
      id: id,
      title: title,
      category: 'Kosmos',
      shortText: 'Krótki tekst',
      longText: 'Długi tekst',
      sourceLabel: 'NASA',
      status: status,
      offer: offer,
      hasOfferColumn: true,
    );
  }

  AdminFact partner(String id, {String? until, String? status}) {
    return AdminFact.partner(
      id: id,
      title: 'Partnerska',
      shortText: 'Krótki tekst',
      longText: 'Długi tekst',
      sourceLabel: 'NASA',
      sourceUrl: null,
      offer: offer(until: until),
      status: status ?? AdminFact.published,
    );
  }

  group('entries', () {
    test('lists partner facts first, then the soonest to end', () {
      final entries = service.entries(
        [
          regular('fact-1', offer: offer(until: '2026-12-31')),
          regular('fact-2'),
          regular('fact-3', offer: offer(until: '2026-11-28')),
          partner('partner-001'),
        ],
        const {},
        now,
      );

      expect(entries.map((entry) => entry.fact.id), [
        'partner-001',
        'fact-3',
        'fact-1',
      ]);
    });

    test('leaves out withdrawn and rejected facts', () {
      final entries = service.entries(
        [
          partner('partner-001', status: AdminFact.withdrawn),
          regular('fact-1', offer: offer(), status: AdminFact.rejected),
          regular('fact-2', offer: offer(), status: AdminFact.draft),
        ],
        const {},
        now,
      );

      expect(entries.map((entry) => entry.fact.id), ['fact-2']);
    });

    test('tells active, ending and ended offers apart', () {
      final entries = service.entries(
        [
          regular('a', offer: offer()),
          regular('b', offer: offer(until: '2026-12-02')),
          regular('c', offer: offer(until: '2026-12-03')),
          regular('d', offer: offer(until: '2026-11-24')),
        ],
        const {},
        now,
      );
      final status = {for (final entry in entries) entry.fact.id: entry.status};

      expect(status, {
        'a': OfferStatus.active,
        'b': OfferStatus.endingSoon,
        'c': OfferStatus.active,
        'd': OfferStatus.ended,
      });
    });

    test('clicks are unknown before offers_stats.sql', () {
      final entries = service.entries(
        [regular('fact-1', offer: offer())],
        {'fact-1': FactUsage.fromJson(_stats())},
        now,
      );

      expect(entries.single.clicks, isNull);
      expect(service.summarize(entries).clicks, isNull);
    });

    test('with the column, a fact without taps has 0', () {
      final entries = service.entries(
        [
          regular('fact-1', offer: offer()),
          regular('fact-2', offer: offer(until: '2026-11-30')),
        ],
        {
          'fact-1': FactUsage.fromJson({..._stats(), 'offer_clicked': 4}),
        },
        now,
      );

      expect(entries.map((entry) => entry.clicks), [0, 4]);
      final summary = service.summarize(entries);
      expect(summary.clicks, 4);
      expect(summary.active, 2);
      expect(summary.endingSoon, 1);
    });
  });

  test('withoutOffer finds regular facts that can take one', () {
    final found = service.withoutOffer([
      regular('fact-1', title: 'Wenus'),
      regular('fact-2', title: 'Mars', offer: offer()),
      regular('fact-3', title: 'Wenus', status: AdminFact.rejected),
      regular('fact-4', title: 'Saturn'),
      partner('partner-001'),
    ], 'wenus');

    expect(found.map((fact) => fact.id), ['fact-1']);
  });

  test('partner facts get their own numbers', () {
    expect(service.nextPartnerId([regular('fact-120')]), 'partner-001');
    expect(
      service.nextPartnerId([partner('partner-009'), regular('fact-3')]),
      'partner-010',
    );
  });
}

Map<String, dynamic> _stats() {
  return {
    'fact_id': 'fact-1',
    'shown': 1,
    'liked': 0,
    'opened': 0,
    'shared': 0,
    'quiz_correct': 0,
    'quiz_wrong': 0,
  };
}
