import 'package:dziesiatka/models/fact.dart';
import 'package:dziesiatka/models/fact_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fact = Fact(
    id: '1',
    title: 'Tytuł',
    category: 'Kosmos',
    shortText: 'Zajawka',
    longText: 'Rozwinięcie',
    sourceLabel: 'Przykład',
    sourceUrl: 'https://example.com',
    isWithdrawn: true,
    isRead: true,
    isFavorite: true,
    lastReadAt: DateTime.utc(2026, 2, 3, 4, 5, 6),
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
    updatedAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
  );

  void expectSameContent(Fact actual, Fact expected) {
    expect(actual.id, expected.id);
    expect(actual.title, expected.title);
    expect(actual.category, expected.category);
    expect(actual.shortText, expected.shortText);
    expect(actual.longText, expected.longText);
    expect(actual.sourceLabel, expected.sourceLabel);
    expect(actual.sourceUrl, expected.sourceUrl);
    expect(actual.isWithdrawn, expected.isWithdrawn);
    expect(actual.createdAt, expected.createdAt);
    expect(actual.updatedAt, expected.updatedAt);
  }

  test('toJson and fromJson round-trip the content', () {
    expectSameContent(Fact.fromJson(fact.toJson()), fact);
  });

  test('toJson leaves out the user\'s state', () {
    final json = fact.toJson();

    expect(json.containsKey('isRead'), isFalse);
    expect(json.containsKey('isFavorite'), isFalse);
    expect(json.containsKey('lastReadAt'), isFalse);
  });

  test('state round-trips through JSON', () {
    final restored = FactState.fromJson(fact.state.toJson());

    expect(restored.isRead, isTrue);
    expect(restored.isFavorite, isTrue);
    expect(restored.lastReadAt, fact.lastReadAt);
  });

  test('updatedAt falls back to createdAt', () {
    final json = fact.toJson()..remove('updatedAt');

    expect(Fact.fromJson(json).updatedAt, fact.createdAt);
  });

  test('copyWith changes only the given fields', () {
    final copy = fact.copyWith(shortText: 'Inna', isRead: false);

    expect(copy.shortText, 'Inna');
    expect(copy.isRead, isFalse);
    expect(copy.isFavorite, isTrue);
    expectSameContent(copy.copyWith(shortText: 'Zajawka'), fact);
  });

  test('withState replaces the state and can clear the read date', () {
    final cleared = fact.withState(const FactState());

    expect(cleared.isRead, isFalse);
    expect(cleared.isFavorite, isFalse);
    expect(cleared.lastReadAt, isNull);
    expect(cleared.title, fact.title);
  });

  test('a default state is recognized', () {
    expect(const FactState().isDefault, isTrue);
    expect(const FactState(isFavorite: true).isDefault, isFalse);
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
    expect(restored.sourceLabel, isEmpty);
    expect(restored.sourceUrl, isNull);
  });

  test('fromJson reads facts saved with the old source field', () {
    final restored = Fact.fromJson({
      'id': 'old',
      'title': 'Stary fakt',
      'category': 'Historia',
      'shortText': 'Zajawka',
      'longText': 'Rozwinięcie',
      'source': 'Encyklopedia',
      'createdAt': '2026-01-01T00:00:00.000Z',
    });

    expect(restored.sourceLabel, 'Encyklopedia');
  });
}
