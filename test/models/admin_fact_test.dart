import 'package:dziesiatka/models/admin_fact.dart';
import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const categories = {'Kosmos'};

  AdminFact fact({
    String title = 'Tytuł',
    String category = 'Kosmos',
    String shortText = 'Krótki tekst.',
    String longText = 'Długi tekst.',
    String sourceLabel = 'NASA',
    String? sourceUrl = 'https://nasa.gov',
    String status = AdminFact.published,
    QuizQuestion? quiz,
  }) {
    return AdminFact(
      id: 'fact-1',
      title: title,
      category: category,
      shortText: shortText,
      longText: longText,
      sourceLabel: sourceLabel,
      sourceUrl: sourceUrl,
      status: status,
      quiz: quiz,
    );
  }

  test('a complete fact has no errors', () {
    expect(fact().validationErrors(categories), isEmpty);
  });

  test('the database limits are checked', () {
    final errors = fact(
      title: 'x' * 61,
      shortText: 'x' * 121,
      longText: ' ',
      sourceLabel: '',
      sourceUrl: 'ftp://nasa.gov',
      category: 'Inna',
      status: 'nieznany',
    ).validationErrors(categories);

    expect(errors, hasLength(7));
  });

  test('a quiz needs 3 different answers and a valid index', () {
    final errors = fact(
      quiz: const QuizQuestion(
        question: 'Pytanie?',
        options: ['A', 'A', 'B'],
        correctIndex: 3,
      ),
    ).validationErrors(categories);

    expect(errors, hasLength(2));
  });

  test('an imported fact is a draft unless it says otherwise', () {
    final imported = AdminFact.fromImport({'title': 'Tytuł'});

    expect(imported.status, AdminFact.draft);
    expect(imported.id, isEmpty);
  });

  test('a row keeps its status and note', () {
    final read = AdminFact.fromRow({
      'id': 'fact-1',
      'title': 'Tytuł',
      'category': 'Kosmos',
      'short_text': 'Krótki',
      'long_text': 'Długi',
      'source_label': 'NASA',
      'source_url': null,
      'status': 'draft',
      'quiz': null,
      'review_note': 'Jedno źródło.',
    });

    expect(read.toRow()['status'], 'draft');
    expect(read.toRow()['review_note'], 'Jedno źródło.');
  });

  test('editing can clear the source and the note', () {
    final edited = fact()
        .copyWith(reviewNote: 'Uwaga')
        .withEdits(
          title: 'Nowy',
          category: 'Kosmos',
          shortText: 'Krótki',
          longText: 'Długi',
          sourceLabel: 'NASA',
          sourceUrl: null,
          quiz: null,
          reviewNote: null,
          offer: null,
        );

    expect(edited.sourceUrl, isNull);
    expect(edited.reviewNote, isNull);
  });

  group('partner fact', () {
    const offer = FactOffer(
      product: 'Atlas',
      shop: 'Sklep',
      url: 'https://example.com',
    );

    AdminFact partner({FactOffer? offer = offer}) {
      return AdminFact.partner(
        id: 'partner-001',
        title: 'Tytuł',
        shortText: 'Krótki tekst.',
        longText: 'Długi tekst.',
        sourceLabel: 'NASA',
        sourceUrl: null,
        offer: offer,
      );
    }

    test('needs no category from the list', () {
      expect(partner().validationErrors(categories), isEmpty);
      expect(partner().category, FactKind.partnerCategory);
      expect(partner().status, AdminFact.published);
    });

    test('needs an offer', () {
      expect(
        partner(offer: null).validationErrors(categories),
        contains('Ciekawostka partnerska musi mieć produkt, sklep i link.'),
      );
    });

    test('saves its kind and offer', () {
      final row = partner().toRow();

      expect(row['kind'], 'partner');
      expect(row['category'], FactKind.partnerCategory);
      expect(row['offer'], offer.toJson());
      expect(row['quiz'], isNull);
    });

    test('a regular fact leaves kind out before the migration', () {
      expect(fact().toRow().containsKey('kind'), isFalse);
    });

    test('reads kind from a row', () {
      final row = {...partner().toRow(), 'status': 'published'};

      final read = AdminFact.fromRow(row);

      expect(read.isPartner, isTrue);
      expect(read.hasKindColumn, isTrue);
      expect(read.copyWith(title: 'Nowy').isPartner, isTrue);
    });

    test('a row without kind is regular', () {
      final row = fact().toRow()..remove('kind');

      final read = AdminFact.fromRow(row);

      expect(read.isPartner, isFalse);
      expect(read.hasKindColumn, isFalse);
    });
  });
}
