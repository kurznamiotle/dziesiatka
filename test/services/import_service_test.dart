import 'dart:convert';

import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/services/import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ImportService();
  const categories = {'Kosmos', 'Historia'};
  const existing = [
    AdminFact(
      id: 'fact-220',
      title: 'Burza większa od Ziemi',
      category: 'Kosmos',
      shortText: 'Wielka Czerwona Plama na Jowiszu to burza szersza od Ziemi.',
      longText: 'Długi tekst.',
      sourceLabel: 'NASA',
      status: AdminFact.published,
    ),
    AdminFact(
      id: 'seed-999',
      title: 'Stara ciekawostka',
      category: 'Historia',
      shortText: 'Coś z dawnych czasów.',
      longText: 'Długi tekst.',
      sourceLabel: 'Britannica',
      status: AdminFact.published,
    ),
  ];

  Map<String, dynamic> item({
    String title = 'Nowy tytuł',
    String shortText = 'Mrówki potrafią uprawiać własne ogrody grzybów.',
    String category = 'Kosmos',
    String status = 'published',
    String? reviewNote,
  }) {
    return {
      'title': title,
      'category': category,
      'short_text': shortText,
      'long_text': 'Pierwszy.\n\nDrugi.',
      'source_label': 'NASA',
      'source_url': 'https://nasa.gov/a',
      'quiz': {
        'question': 'Pytanie?',
        'options': ['A', 'B', 'C'],
        'correctIndex': 1,
      },
      'status': status,
      'review_note': reviewNote,
    };
  }

  List<dynamic> check(List<Map<String, dynamic>> items) {
    return service.check(
      jsonEncode(items),
      existing: existing,
      categories: categories,
    );
  }

  test('a good item passes', () {
    final checked = service.check(
      jsonEncode([item()]),
      existing: existing,
      categories: categories,
    );

    expect(checked.single.isValid, isTrue);
    expect(checked.single.duplicateOf, isNull);
  });

  test('a code fence from a chat is ignored', () {
    final checked = service.check(
      '```json\n${jsonEncode([item()])}\n```',
      existing: existing,
      categories: categories,
    );

    expect(checked, hasLength(1));
  });

  test('anything but a JSON list is refused', () {
    expect(
      () => service.check('{"a": 1}', existing: existing, categories: {}),
      throwsFormatException,
    );
    expect(
      () => service.check('nie json', existing: existing, categories: {}),
      throwsFormatException,
    );
  });

  test('a bad item is reported and the rest stay', () {
    final checked = service.check(
      jsonEncode([item(category: 'Nieznana'), item(title: 'Inny tytuł')]),
      existing: existing,
      categories: categories,
    );

    expect(checked.first.isValid, isFalse);
    expect(checked.last.isValid, isTrue);
  });

  test('an item of a wrong shape does not stop the check', () {
    final checked = check([
      {'title': 123},
      item(),
    ]);

    expect(checked.first.isValid, isFalse);
    expect(checked.last.isValid, isTrue);
  });

  test('the same title counts as a duplicate', () {
    final checked = service.check(
      jsonEncode([item(title: 'BURZA WIĘKSZA OD ZIEMI ')]),
      existing: existing,
      categories: categories,
    );

    expect(checked.single.duplicateOf, 'Burza większa od Ziemi');
  });

  test('the same fact in other words counts as a duplicate', () {
    final checked = service.check(
      jsonEncode([
        item(
          title: 'Burza szersza od Ziemi',
          shortText: 'Wielka Czerwona Plama Jowisza to burza większa od Ziemi.',
        ),
      ]),
      existing: existing,
      categories: categories,
    );

    expect(checked.single.duplicateOf, 'Burza większa od Ziemi');
  });

  test('two similar items in one file are caught', () {
    final checked = service.check(
      jsonEncode([item(), item()]),
      existing: existing,
      categories: categories,
    );

    expect(checked.first.duplicateOf, isNull);
    expect(checked.last.duplicateOf, 'Nowy tytuł');
  });

  group('preparing to save', () {
    List<AdminFact> prepare(
      List<Map<String, dynamic>> items, {
      bool publishConfident = false,
    }) {
      return service.prepareToSave(
        service.check(
          jsonEncode(items),
          existing: existing,
          categories: categories,
        ),
        existing: existing,
        publishConfident: publishConfident,
      );
    }

    test('ids continue after the highest number', () {
      final facts = prepare([
        item(),
        item(title: 'Coś innego', shortText: 'Zupełnie inna treść tekstu.'),
      ]);

      expect(facts.map((fact) => fact.id), ['fact-221', 'fact-222']);
    });

    test('items with errors are left out', () {
      expect(prepare([item(category: 'Nieznana')]), isEmpty);
    });

    test('by default everything is a draft', () {
      expect(prepare([item()]).single.status, AdminFact.draft);
    });

    test('confident items can be published at once', () {
      final facts = prepare([item()], publishConfident: true);

      expect(facts.single.status, AdminFact.published);
    });

    test('a doubt from the chat stays a draft with its reason', () {
      final facts = prepare([
        item(status: 'draft', reviewNote: 'Jedno źródło.'),
      ], publishConfident: true);

      expect(facts.single.status, AdminFact.draft);
      expect(facts.single.reviewNote, 'Jedno źródło.');
    });

    test('a published item with a note also stays a draft', () {
      final facts = prepare([
        item(reviewNote: 'Sprawdź datę.'),
      ], publishConfident: true);

      expect(facts.single.status, AdminFact.draft);
    });

    test('a possible duplicate stays a draft with a note', () {
      final facts = prepare([
        item(title: 'Burza większa od Ziemi'),
      ], publishConfident: true);

      expect(facts.single.status, AdminFact.draft);
      expect(facts.single.reviewNote, contains('Burza większa od Ziemi'));
    });
  });
}
