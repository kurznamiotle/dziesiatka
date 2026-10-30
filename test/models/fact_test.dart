import 'package:dziesiatka/models/fact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fact = Fact(
    id: '1',
    title: 'Tytuł',
    category: 'Kosmos',
    shortText: 'Zajawka',
    longText: 'Rozwinięcie',
    source: 'https://example.com',
    isRead: true,
    isFavorite: true,
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
  );

  void expectSameFields(Fact actual, Fact expected) {
    expect(actual.id, expected.id);
    expect(actual.title, expected.title);
    expect(actual.category, expected.category);
    expect(actual.shortText, expected.shortText);
    expect(actual.longText, expected.longText);
    expect(actual.source, expected.source);
    expect(actual.isRead, expected.isRead);
    expect(actual.isFavorite, expected.isFavorite);
    expect(actual.createdAt, expected.createdAt);
  }

  test('toJson and fromJson round-trip all fields', () {
    expectSameFields(Fact.fromJson(fact.toJson()), fact);
  });

  test('copyWith changes only the given fields', () {
    final copy = fact.copyWith(shortText: 'Inna', isRead: false);

    expect(copy.shortText, 'Inna');
    expect(copy.isRead, isFalse);
    expectSameFields(copy.copyWith(shortText: 'Zajawka', isRead: true), fact);
  });

  test('fromJson defaults isRead and isFavorite to false when missing', () {
    final json = fact.toJson()
      ..remove('isRead')
      ..remove('isFavorite');

    final restored = Fact.fromJson(json);

    expect(restored.isRead, isFalse);
    expect(restored.isFavorite, isFalse);
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
    expect(restored.source, isEmpty);
    expect(restored.isRead, isTrue);
  });
}
