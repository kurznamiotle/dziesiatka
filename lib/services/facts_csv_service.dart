import 'package:dziesiatka/models/admin_fact.dart';

/// Writes the list a chat reads to avoid repeating existing facts, and reads
/// it back when a chat filled in the offer columns.
class FactsCsvService {
  const FactsCsvService();

  /// Excel recognizes UTF-8 only with this mark at the start.
  static const _byteOrderMark = '﻿';

  static const offerColumns = [
    'offer_product',
    'offer_shop',
    'offer_url',
    'offer_until',
  ];

  /// Partner facts are left out, as a chat writes only regular ones.
  String encode(List<AdminFact> facts) {
    final rows = [
      ['id', 'status', 'category', 'title', 'short_text', ...offerColumns],
      for (final fact in facts.where((fact) => !fact.isPartner))
        [
          fact.id,
          fact.status,
          fact.category,
          fact.title,
          fact.shortText,
          fact.offer?.product ?? '',
          fact.offer?.shop ?? '',
          fact.offer?.url ?? '',
          fact.offer?.until ?? '',
        ],
    ];
    final lines = rows.map((row) => row.map(_cell).join(','));
    return '$_byteOrderMark${lines.join('\r\n')}\r\n';
  }

  /// Reads a file with a header row into one map per row, keyed by the header.
  /// Accepts commas or semicolons, as Excel in Polish saves with semicolons.
  /// Throws [FormatException] if the quotes do not close.
  List<Map<String, String>> decode(String text) {
    var source = text.startsWith(_byteOrderMark) ? text.substring(1) : text;
    source = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final firstLine = source.split('\n').first;
    final separator =
        ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
        ? ';'
        : ',';

    final rows = _rows(
      source,
      separator,
    ).where((row) => row.any((cell) => cell.trim().isNotEmpty)).toList();
    if (rows.isEmpty) return const [];

    final header = [for (final cell in rows.first) cell.trim()];
    return [
      for (final row in rows.skip(1))
        {
          for (final (index, name) in header.indexed)
            name: index < row.length ? row[index] : '',
        },
    ];
  }

  List<List<String>> _rows(String source, String separator) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (inQuotes) {
        if (char != '"') {
          cell.write(char);
        } else if (i + 1 < source.length && source[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else if (char == '"') {
        inQuotes = true;
      } else if (char == separator) {
        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n') {
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(char);
      }
    }
    if (inQuotes) throw const FormatException('Niezamknięty cudzysłów.');
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  String _cell(String value) {
    final needsQuotes = RegExp(r'[",;\r\n]').hasMatch(value);
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
