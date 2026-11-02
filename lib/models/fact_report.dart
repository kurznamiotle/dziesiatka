enum FactReportReason {
  wrongFact('wrong_fact', 'Nieprawdziwa informacja'),
  language('language', 'Literówka lub błąd językowy'),
  source('source', 'Problem ze źródłem'),
  other('other', 'Coś innego');

  const FactReportReason(this.code, this.label);

  final String code;
  final String label;

  static FactReportReason fromCode(String code) {
    return values.firstWhere(
      (reason) => reason.code == code,
      orElse: () => other,
    );
  }
}

/// A reader's report of a mistake in a fact, as the panel sees it.
class FactReport {
  const FactReport({
    required this.id,
    required this.factId,
    required this.reason,
    required this.comment,
    required this.createdAt,
  });

  factory FactReport.fromRow(Map<String, dynamic> row) {
    return FactReport(
      id: row['id'] as int,
      factId: row['fact_id'] as String,
      reason: FactReportReason.fromCode(row['reason'] as String),
      comment: row['comment'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  final int id;
  final String factId;
  final FactReportReason reason;
  final String comment;
  final DateTime createdAt;
}
