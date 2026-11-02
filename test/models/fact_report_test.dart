import 'package:dziesiatka/models/fact_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a row becomes a report', () {
    final report = FactReport.fromRow({
      'id': 7,
      'fact_id': 'seed-001',
      'reason': 'language',
      'comment': 'Literówka w tytule.',
      'created_at': '2026-11-02T10:00:00+00:00',
    });

    expect(report.id, 7);
    expect(report.factId, 'seed-001');
    expect(report.reason, FactReportReason.language);
    expect(report.comment, 'Literówka w tytule.');
    expect(report.createdAt.toUtc(), DateTime.utc(2026, 11, 2, 10));
  });

  test('a missing comment is empty', () {
    final report = FactReport.fromRow({
      'id': 7,
      'fact_id': 'seed-001',
      'reason': 'source',
      'comment': null,
      'created_at': '2026-11-02T10:00:00+00:00',
    });

    expect(report.comment, isEmpty);
  });

  test('an unknown reason counts as other', () {
    expect(FactReportReason.fromCode('nowy'), FactReportReason.other);
  });
}
