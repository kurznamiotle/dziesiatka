import 'package:dziesiatka/models/admin_fact.dart';

/// Writes the list a chat reads to avoid repeating existing facts.
class FactsCsvService {
  const FactsCsvService();

  /// Excel recognizes UTF-8 only with this mark at the start.
  static const _byteOrderMark = '﻿';

  String encode(List<AdminFact> facts) {
    final rows = [
      ['id', 'status', 'category', 'title', 'short_text'],
      for (final fact in facts)
        [fact.id, fact.status, fact.category, fact.title, fact.shortText],
    ];
    final lines = rows.map((row) => row.map(_cell).join(','));
    return '$_byteOrderMark${lines.join('\r\n')}\r\n';
  }

  String _cell(String value) {
    final needsQuotes = RegExp(r'[",\r\n]').hasMatch(value);
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
