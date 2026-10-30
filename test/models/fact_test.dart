import 'package:dziesiatka/models/fact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fact = Fact(
    id: '1',
    title: 'Tytuł',
    content: 'Treść',
    category: 'Kosmos',
    isRead: true,
    createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
  );

  test('toJson and fromJson round-trip all fields', () {
    final restored = Fact.fromJson(fact.toJson());

    expect(restored.id, fact.id);
    expect(restored.title, fact.title);
    expect(restored.content, fact.content);
    expect(restored.category, fact.category);
    expect(restored.isRead, fact.isRead);
    expect(restored.createdAt, fact.createdAt);
  });

  test('fromJson defaults isRead to false when missing', () {
    final json = fact.toJson()..remove('isRead');

    expect(Fact.fromJson(json).isRead, isFalse);
  });
}
