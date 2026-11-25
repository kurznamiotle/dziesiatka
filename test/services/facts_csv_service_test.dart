import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/services/facts_csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FactsCsvService();

  AdminFact fact(String title) {
    return AdminFact(
      id: 'fact-1',
      title: title,
      category: 'Kosmos',
      shortText: 'Krótki, z przecinkiem',
      longText: 'Długi',
      sourceLabel: 'NASA',
      status: AdminFact.draft,
    );
  }

  test('starts with a mark Excel needs and a header', () {
    final csv = service.encode([]);

    expect(csv.codeUnitAt(0), 0xFEFF);
    expect(
      csv.substring(1),
      'id,status,category,title,short_text,offer_product,offer_shop,'
      'offer_url,offer_until\r\n',
    );
  });

  test('quotes commas and quotation marks', () {
    final csv = service.encode([fact('Tytuł "w cudzysłowie"')]);

    expect(
      csv,
      contains(
        'fact-1,draft,Kosmos,"Tytuł ""w cudzysłowie""",'
        '"Krótki, z przecinkiem"',
      ),
    );
  });

  test('leaves the long text out, as a chat does not need it', () {
    expect(service.encode([fact('Tytuł')]), isNot(contains('Długi')));
  });

  test('writes the offer columns', () {
    const offer = FactOffer(
      product: 'Atlas',
      shop: 'Sklep',
      url: 'https://example.com/a',
      until: '2026-12-31',
    );
    final csv = service.encode([
      const AdminFact(
        id: 'fact-1',
        title: 'T',
        category: 'Kosmos',
        shortText: 'K',
        longText: 'D',
        sourceLabel: 'NASA',
        status: AdminFact.published,
        offer: offer,
      ),
    ]);

    expect(csv, contains('Atlas,Sklep,https://example.com/a,2026-12-31'));
  });

  group('decode', () {
    test('reads back what encode wrote', () {
      final rows = service.decode(service.encode([fact('Tytuł "x"')]));

      expect(rows.single['id'], 'fact-1');
      expect(rows.single['title'], 'Tytuł "x"');
      expect(rows.single['short_text'], 'Krótki, z przecinkiem');
      expect(rows.single['offer_product'], '');
    });

    test('accepts semicolons and lines broken inside quotes', () {
      final rows = service.decode(
        'id;title;offer_product\n'
        'fact-1;"Dwie\nlinie";Atlas\n'
        '\n',
      );

      expect(rows.single, {
        'id': 'fact-1',
        'title': 'Dwie\nlinie',
        'offer_product': 'Atlas',
      });
    });

    test('a short row gets empty cells', () {
      final rows = service.decode('id,offer_product,offer_shop\nfact-1,Atlas');

      expect(rows.single['offer_shop'], '');
    });

    test('rejects an unclosed quote', () {
      expect(() => service.decode('id\n"fact-1'), throwsFormatException);
    });
  });

  test('partner facts stay out of the file for the chat', () {
    final partner = AdminFact(
      id: 'partner-001',
      title: 'Partnerska',
      category: FactKind.partnerCategory,
      shortText: 'Krótki',
      longText: 'Długi',
      sourceLabel: 'NASA',
      status: AdminFact.published,
      kind: FactKind.partner,
    );

    final csv = service.encode([fact('Zwykła'), partner]);

    expect(csv, contains('Zwykła'));
    expect(csv, isNot(contains('Partnerska')));
  });
}
