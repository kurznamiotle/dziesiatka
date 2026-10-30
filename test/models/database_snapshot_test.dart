import 'package:dziesiatka/models/database_snapshot.dart';
import 'package:dziesiatka/models/fact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> factJson({String id = '1', String category = 'Kosmos'}) {
    return Fact(
      id: id,
      title: 'Tytuł',
      category: category,
      shortText: 'Zajawka',
      longText: 'Rozwinięcie',
      source: 'Źródło',
      createdAt: DateTime.utc(2026),
    ).toJson();
  }

  test('toJson and fromJson round-trip the database', () {
    final snapshot = DatabaseSnapshot.fromJson({
      'categories': ['Kosmos'],
      'facts': [factJson()],
    });

    final restored = DatabaseSnapshot.fromJson(snapshot.toJson());

    expect(restored.categories, ['Kosmos']);
    expect(restored.facts.single.title, 'Tytuł');
  });

  test('categories used by facts are added to the list', () {
    final snapshot = DatabaseSnapshot.fromJson({
      'categories': ['Kosmos'],
      'facts': [factJson(category: 'Muzyka')],
    });

    expect(snapshot.categories, ['Kosmos', 'Muzyka']);
  });

  group('rejects', () {
    void expectRejected(Map<String, dynamic> json) {
      expect(() => DatabaseSnapshot.fromJson(json), throwsFormatException);
    }

    test('missing lists', () {
      expectRejected({'facts': <dynamic>[]});
      expectRejected({'categories': <dynamic>[]});
    });

    test('duplicate fact ids', () {
      expectRejected({
        'categories': <dynamic>[],
        'facts': [factJson(), factJson()],
      });
    });

    test('a fact without a required field', () {
      expectRejected({
        'categories': <dynamic>[],
        'facts': [factJson()..remove('longText')],
      });
    });

    test('a fact with an empty field or a wrong type', () {
      expectRejected({
        'categories': <dynamic>[],
        'facts': [factJson()..['title'] = '  '],
      });
      expectRejected({
        'categories': <dynamic>[],
        'facts': [factJson()..['isRead'] = 'tak'],
      });
    });

    test('a fact with an invalid date', () {
      expectRejected({
        'categories': <dynamic>[],
        'facts': [factJson()..['createdAt'] = 'wczoraj'],
      });
    });

    test('an invalid category', () {
      expectRejected({
        'categories': [1],
        'facts': <dynamic>[],
      });
    });
  });
}
