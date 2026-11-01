import 'package:dziesiatka/models/admin_fact.dart';
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
    expect(csv.substring(1), 'id,status,category,title,short_text\r\n');
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
}
