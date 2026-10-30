import 'package:dziesiatka/models/fact.dart';

/// The whole local database in its export format.
class DatabaseSnapshot {
  const DatabaseSnapshot({required this.categories, required this.facts});

  /// Throws a [FormatException] with a user-facing message when [json] is not
  /// a complete export, because an import replaces all existing data.
  factory DatabaseSnapshot.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final rawFacts = json['facts'];
    if (rawCategories is! List || rawFacts is! List) {
      throw const FormatException('Brakuje list „categories” lub „facts”.');
    }

    final facts = rawFacts.map(_parseFact).toList();
    if (facts.map((fact) => fact.id).toSet().length != facts.length) {
      throw const FormatException('Identyfikatory faktów się powtarzają.');
    }

    return DatabaseSnapshot(
      categories: {
        ...rawCategories.map(_parseCategory),
        ...facts.map((fact) => fact.category),
      }.toList(),
      facts: facts,
    );
  }

  final List<String> categories;
  final List<Fact> facts;

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'categories': categories,
      'facts': facts.map((fact) => fact.toJson()).toList(),
    };
  }

  static String _parseCategory(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw const FormatException('Lista kategorii zawiera błędną wartość.');
  }

  static Fact _parseFact(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Lista faktów zawiera błędną wartość.');
    }
    const requiredFields = [
      'id',
      'title',
      'category',
      'shortText',
      'longText',
      'createdAt',
    ];
    for (final field in requiredFields) {
      final fieldValue = value[field];
      if (fieldValue is! String || fieldValue.trim().isEmpty) {
        throw FormatException('Fakt nie ma poprawnego pola „$field”.');
      }
    }
    if (value['source'] is! String? || value['isRead'] is! bool?) {
      throw const FormatException('Fakt ma błędne pole „source” lub „isRead”.');
    }
    if (DateTime.tryParse(value['createdAt'] as String) == null) {
      throw const FormatException('Fakt ma błędną datę „createdAt”.');
    }
    return Fact.fromJson(value);
  }
}
