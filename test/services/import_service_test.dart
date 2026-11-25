import 'dart:convert';

import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/models/fact_offer.dart';
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

  group('offers in an import', () {
    test('a JSON item can bring an offer', () {
      final items = service.check(
        jsonEncode([
          {
            ...item(),
            'offer_product': 'Atlas',
            'offer_shop': 'Sklep',
            'offer_url': 'https://example.com',
          },
        ]),
        existing: existing,
        categories: categories,
      );

      expect(items.single.isValid, isTrue);
      expect(items.single.fact.offer?.product, 'Atlas');
      final saved = service.prepareToSave(
        items,
        existing: existing,
        publishConfident: false,
      );
      expect(saved.single.toRow()['offer'], isNotNull);
    });

    test('a partly filled offer is an error', () {
      final items = service.check(
        jsonEncode([
          {...item(), 'offer_product': 'Atlas'},
        ]),
        existing: existing,
        categories: categories,
      );

      expect(items.single.isValid, isFalse);
    });

    test('an item without offer columns saves no offer key', () {
      final items = service.check(
        jsonEncode([item()]),
        existing: existing,
        categories: categories,
      );
      final saved = service.prepareToSave(
        items,
        existing: existing,
        publishConfident: false,
      );

      expect(saved.single.toRow().containsKey('offer'), isFalse);
    });
  });

  group('checkOffers', () {
    final withColumn = [
      for (final fact in existing)
        AdminFact.fromRow({...fact.toRow(), 'offer': null}),
    ];
    const header = 'id,title,offer_product,offer_shop,offer_url,offer_until';

    test('tells a CSV file from a JSON one', () {
      expect(service.isOfferFile('﻿id,title\n'), isTrue);
      expect(service.isOfferFile('  [{"title": "A"}]'), isFalse);
      expect(service.isOfferFile('```json\n[]\n```'), isFalse);
    });

    test('sets filled offers and skips empty rows', () {
      final items = service.checkOffers(
        '$header\n'
        'fact-220,Burza,Atlas,Sklep,https://example.com/a,2026-12-31\n'
        'seed-999,Stara,,,,\n',
        existing: withColumn,
      );

      expect(items, hasLength(1));
      expect(items.single.factId, 'fact-220');
      expect(items.single.title, 'Burza większa od Ziemi');
      expect(items.single.isValid, isTrue);
      expect(items.single.offer.until, '2026-12-31');
    });

    test('a file without offer columns changes nothing', () {
      final items = service.checkOffers(
        'id,title\nfact-220,Burza\n',
        existing: withColumn,
      );

      expect(items, isEmpty);
    });

    test('an offer already saved is left out', () {
      final known = [
        withColumn.first.withEdits(
          title: withColumn.first.title,
          category: 'Kosmos',
          shortText: withColumn.first.shortText,
          longText: withColumn.first.longText,
          sourceLabel: 'NASA',
          sourceUrl: null,
          quiz: null,
          reviewNote: null,
          offer: const FactOffer(
            product: 'Atlas',
            shop: 'Sklep',
            url: 'https://example.com/a',
          ),
        ),
      ];

      final items = service.checkOffers(
        '$header\nfact-220,B,Atlas,Sklep,https://example.com/a,\n',
        existing: known,
      );

      expect(items, isEmpty);
    });

    test('names unknown ids, bad offers and a missing column', () {
      final items = service.checkOffers(
        '$header\n'
        'fact-404,X,Atlas,Sklep,https://example.com,\n'
        'fact-220,B,Atlas,Sklep,http://example.com,31.12.2026\n',
        existing: withColumn,
      );
      final beforeMigration = service.checkOffers(
        '$header\nfact-220,B,Atlas,Sklep,https://example.com,\n',
        existing: existing,
      );

      expect(items[0].errors.single, contains('fact-404'));
      expect(items[1].errors, hasLength(2));
      expect(beforeMigration.single.errors.single, contains('offers.sql'));
    });

    test('a file without an id column is rejected', () {
      expect(
        () => service.checkOffers('title\nA\n', existing: existing),
        throwsFormatException,
      );
    });
  });

  group('partner facts in an import', () {
    // Rows read after supabase/partner_facts.sql, so the database knows kind.
    final withKind = [
      for (final fact in existing)
        AdminFact.fromRow({...fact.toRow(), 'kind': 'regular'}),
    ];

    Map<String, dynamic> partner({
      String title = 'Ośmiornica myśli ramionami',
      Map<String, dynamic>? quiz,
      bool withOffer = true,
      String status = 'published',
    }) {
      return {
        'kind': 'partner',
        'title': title,
        'short_text': 'Większość neuronów ośmiornicy siedzi w ramionach.',
        'long_text': 'Rozwinięcie.',
        'source_label': 'Peter Godfrey-Smith',
        'status': status,
        'quiz': ?quiz,
        if (withOffer) ...{
          'offer_product': 'Inne umysły',
          'offer_shop': 'Znak',
          'offer_url': 'https://www.znak.com.pl/inne-umysly',
          'offer_until': '2026-12-31',
        },
      };
    }

    test('needs neither a category nor a quiz', () {
      final checked = service.check(
        jsonEncode([partner()]),
        existing: withKind,
        categories: categories,
      );

      final item = checked.single;
      expect(item.errors, isEmpty);
      expect(item.fact.isPartner, isTrue);
      expect(item.fact.category, FactKind.partnerCategory);
      expect(item.fact.quiz, isNull);
      expect(
        item.fact.offer,
        const FactOffer(
          product: 'Inne umysły',
          shop: 'Znak',
          url: 'https://www.znak.com.pl/inne-umysly',
          until: '2026-12-31',
        ),
      );
    });

    test('a category in the file is ignored', () {
      final checked = service.check(
        jsonEncode([
          {...partner(), 'category': 'Kosmos'},
        ]),
        existing: withKind,
        categories: const {},
      );

      expect(checked.single.errors, isEmpty);
      expect(checked.single.fact.category, FactKind.partnerCategory);
    });

    test('needs an offer and no quiz', () {
      final checked = service.check(
        jsonEncode([
          partner(withOffer: false, title: 'Bez polecenia'),
          partner(
            title: 'Z quizem',
            quiz: {
              'question': 'Pytanie?',
              'options': ['A', 'B', 'C'],
              'correctIndex': 0,
            },
          ),
        ]),
        existing: withKind,
        categories: categories,
      );

      expect(
        checked[0].errors,
        contains('Ciekawostka partnerska musi mieć produkt, sklep i link.'),
      );
      expect(
        checked[1].errors,
        contains('Ciekawostka partnerska nie ma pytania quizowego.'),
      );
    });

    test('an unknown kind is a wrong shape', () {
      final checked = service.check(
        jsonEncode([
          {...partner(), 'kind': 'reklama'},
        ]),
        existing: withKind,
        categories: categories,
      );

      expect(checked.single.errors, ['Pozycja ma niepoprawny układ pól.']);
    });

    test('a database without kind gets a clear error', () {
      final checked = service.check(
        jsonEncode([partner()]),
        existing: existing,
        categories: categories,
      );

      expect(
        checked.single.errors.single,
        contains('supabase/partner_facts.sql'),
      );
    });

    test('get partner numbers apart from regular ones', () {
      final known = [
        ...withKind,
        AdminFact.partner(
          id: 'partner-002',
          title: 'Stara partnerska',
          shortText: 'Krótki.',
          longText: 'Długi.',
          sourceLabel: 'NASA',
          sourceUrl: null,
          offer: const FactOffer(
            product: 'A',
            shop: 'B',
            url: 'https://example.com',
          ),
        ),
      ];
      final checked = service.check(
        jsonEncode([partner(), item(), partner(title: 'Ptaki są sprytne')]),
        existing: known,
        categories: categories,
      );

      final saved = service.prepareToSave(
        checked,
        existing: known,
        publishConfident: true,
      );

      expect(saved.map((fact) => fact.id), [
        'partner-003',
        'fact-221',
        'partner-004',
      ]);
      final row = saved.first.toRow();
      expect(row['kind'], 'partner');
      expect(row['category'], FactKind.partnerCategory);
      expect(row['status'], AdminFact.published);
      expect((row['offer'] as Map)['shop'], 'Znak');
    });
  });
}
