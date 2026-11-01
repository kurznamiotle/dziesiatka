import 'dart:convert';
import 'dart:math';

import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/import_item.dart';

/// Checks a file prepared by a chat and turns it into facts ready to save.
class ImportService {
  const ImportService();

  static const _similarityLimit = 0.6;
  static const _shortestWord = 4;

  /// Words are cut to this length, so Polish endings still match.
  static const _wordStem = 5;

  /// Reads a JSON list of facts. Throws [FormatException] if it is not one.
  /// Chats often wrap their answer in a code fence, so that is removed first.
  List<ImportItem> check(
    String text, {
    required List<AdminFact> existing,
    required Set<String> categories,
  }) {
    final items = _parse(text);
    final seen = [
      for (final fact in existing) (title: fact.title, words: _wordsOf(fact)),
    ];

    final checked = <ImportItem>[];
    for (final item in items) {
      final AdminFact fact;
      try {
        fact = AdminFact.fromImport(item as Map<String, dynamic>);
      } catch (_) {
        checked.add(
          const ImportItem(
            fact: AdminFact(
              id: '',
              title: '(nieczytelna pozycja)',
              category: '',
              shortText: '',
              longText: '',
              sourceLabel: '',
              status: AdminFact.draft,
            ),
            errors: ['Pozycja ma niepoprawny układ pól.'],
          ),
        );
        continue;
      }

      final words = _wordsOf(fact);
      checked.add(
        ImportItem(
          fact: fact,
          errors: fact.validationErrors(categories),
          duplicateOf: _similarTo(fact, words, seen),
        ),
      );
      seen.add((title: fact.title, words: words));
    }
    return checked;
  }

  /// Gives each valid item the next free id. Items are saved as drafts unless
  /// [publishConfident] is on and nothing raised a doubt about them.
  List<AdminFact> prepareToSave(
    List<ImportItem> items, {
    required List<AdminFact> existing,
    required bool publishConfident,
  }) {
    var number = _lastNumber(existing);
    return [
      for (final item in items.where((item) => item.isValid))
        _prepared(item, ++number, publishConfident: publishConfident),
    ];
  }

  AdminFact _prepared(
    ImportItem item,
    int number, {
    required bool publishConfident,
  }) {
    final fact = item.fact;
    final duplicateOf = item.duplicateOf;
    final isConfident =
        publishConfident &&
        duplicateOf == null &&
        fact.status == AdminFact.published &&
        (fact.reviewNote?.trim().isEmpty ?? true);
    final notes = [
      ?fact.reviewNote,
      if (duplicateOf != null) 'Możliwy duplikat: „$duplicateOf”.',
    ];
    return fact.copyWith(
      id: 'fact-${number.toString().padLeft(3, '0')}',
      status: isConfident ? AdminFact.published : AdminFact.draft,
      reviewNote: notes.isEmpty ? null : notes.join(' '),
    );
  }

  int _lastNumber(List<AdminFact> facts) {
    final pattern = RegExp(r'^fact-(\d+)$');
    return facts.fold(0, (last, fact) {
      final match = pattern.firstMatch(fact.id);
      return match == null ? last : max(last, int.parse(match.group(1)!));
    });
  }

  List<dynamic> _parse(String text) {
    final cleaned = text
        .trim()
        .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    final decoded = jsonDecode(cleaned);
    if (decoded is List<dynamic>) return decoded;
    throw const FormatException('Plik musi zawierać listę ciekawostek.');
  }

  Set<String> _wordsOf(AdminFact fact) {
    return '${fact.title} ${fact.shortText}'
        .toLowerCase()
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((word) => word.length >= _shortestWord)
        .map((word) => word.substring(0, min(word.length, _wordStem)))
        .toSet();
  }

  String? _similarTo(
    AdminFact fact,
    Set<String> words,
    List<({String title, Set<String> words})> seen,
  ) {
    final title = fact.title.trim().toLowerCase();
    for (final known in seen) {
      if (known.title.trim().toLowerCase() == title) return known.title;
      if (_similarity(words, known.words) >= _similarityLimit) {
        return known.title;
      }
    }
    return null;
  }

  double _similarity(Set<String> first, Set<String> second) {
    if (first.isEmpty || second.isEmpty) return 0;
    final shared = first.intersection(second).length;
    return shared / (first.length + second.length - shared);
  }
}
