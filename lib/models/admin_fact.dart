import 'package:dziesiatka/models/fact_kind.dart';
import 'package:dziesiatka/models/fact_offer.dart';
import 'package:dziesiatka/models/quiz_question.dart';

/// A fact as the admin panel sees it, with its publication status. A fact from
/// an imported file has an empty [id] until it is saved.
class AdminFact {
  const AdminFact({
    required this.id,
    required this.title,
    required this.category,
    required this.shortText,
    required this.longText,
    required this.sourceLabel,
    required this.status,
    this.sourceUrl,
    this.quiz,
    this.reviewNote,
    this.offer,
    this.hasOfferColumn = false,
    this.kind = FactKind.regular,
    this.hasKindColumn = false,
  });

  /// A partner fact, published right away, as the panel shows a preview
  /// before saving. It has no quiz and its category is fixed. The [offer] is
  /// required to save, which [validationErrors] checks.
  factory AdminFact.partner({
    required String id,
    required String title,
    required String shortText,
    required String longText,
    required String sourceLabel,
    required String? sourceUrl,
    required FactOffer? offer,
    String status = published,
  }) {
    return AdminFact(
      id: id,
      title: title,
      category: FactKind.partnerCategory,
      shortText: shortText,
      longText: longText,
      sourceLabel: sourceLabel,
      sourceUrl: sourceUrl,
      status: status,
      offer: offer,
      hasOfferColumn: true,
      kind: FactKind.partner,
      hasKindColumn: true,
    );
  }

  factory AdminFact.fromRow(Map<String, dynamic> row) {
    final quiz = row['quiz'] as Map<String, dynamic>?;
    return AdminFact(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      shortText: row['short_text'] as String,
      longText: row['long_text'] as String,
      sourceLabel: row['source_label'] as String,
      sourceUrl: row['source_url'] as String?,
      status: row['status'] as String,
      quiz: quiz == null ? null : QuizQuestion.fromJson(quiz),
      reviewNote: row['review_note'] as String?,
      offer: FactOffer.tryParse(row['offer']),
      hasOfferColumn: row.containsKey('offer'),
      kind: FactKind.fromName(row['kind']),
      hasKindColumn: row.containsKey('kind'),
    );
  }

  /// Reads one item of a file prepared by a chat. Throws on a wrong shape,
  /// such as a number in place of text.
  factory AdminFact.fromImport(Map<String, dynamic> json) {
    final quiz = json['quiz'] as Map<String, dynamic>?;
    return AdminFact(
      id: '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      shortText: json['short_text'] as String? ?? '',
      longText: json['long_text'] as String? ?? '',
      sourceLabel: json['source_label'] as String? ?? '',
      sourceUrl: json['source_url'] as String?,
      status: json['status'] as String? ?? draft,
      quiz: quiz == null ? null : QuizQuestion.fromJson(quiz),
      reviewNote: json['review_note'] as String?,
      offer: offerFromColumns(json),
    );
  }

  /// Reads the `offer_*` columns of an import or a CSV file. All empty or
  /// missing means no offer. A partly filled one comes back with blanks, so
  /// the check names what is missing.
  static FactOffer? offerFromColumns(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String) throw FormatException('$key nie jest tekstem.');
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final product = text('offer_product');
    final shop = text('offer_shop');
    final url = text('offer_url');
    final until = text('offer_until');
    if (product == null && shop == null && url == null && until == null) {
      return null;
    }
    return FactOffer(
      product: product ?? '',
      shop: shop ?? '',
      url: url ?? '',
      until: until,
    );
  }

  static const draft = 'draft';
  static const published = 'published';
  static const withdrawn = 'withdrawn';
  static const rejected = 'rejected';

  static const maxTitleLength = 60;
  static const maxShortTextLength = 120;
  static const quizOptionCount = 3;

  final String id;
  final String title;
  final String category;
  final String shortText;
  final String longText;
  final String sourceLabel;
  final String? sourceUrl;
  final String status;
  final QuizQuestion? quiz;
  final String? reviewNote;
  final FactOffer? offer;

  /// The row came with an `offer` column, so `supabase/offers.sql` has run
  /// and the offer can be saved or removed.
  final bool hasOfferColumn;

  final FactKind kind;

  /// The row came with a `kind` column, so `supabase/partner_facts.sql` has
  /// run and partner facts can be saved.
  final bool hasKindColumn;

  bool get isPartner => kind == FactKind.partner;

  /// Has an offer whose last day has passed.
  bool hasEndedOfferOn(DateTime moment) {
    final offer = this.offer;
    return offer != null && !offer.isActiveOn(moment);
  }

  /// The same rules as the database, so a mistake shows up before saving.
  /// [categories] are the names the database accepts.
  List<String> validationErrors(Set<String> categories) {
    final title = this.title.trim();
    final shortText = this.shortText.trim();
    final sourceUrl = this.sourceUrl;
    return [
      if (title.isEmpty) 'Brak tytułu.',
      if (title.length > maxTitleLength)
        'Tytuł ma ${title.length} znaków, limit to $maxTitleLength.',
      if (shortText.isEmpty) 'Brak krótkiego tekstu.',
      if (shortText.length > maxShortTextLength)
        'Krótki tekst ma ${shortText.length} znaków, limit to '
            '$maxShortTextLength.',
      if (longText.trim().isEmpty) 'Brak długiego tekstu.',
      if (sourceLabel.trim().isEmpty) 'Brak nazwy źródła.',
      if (sourceUrl != null && !RegExp(r'^https?://').hasMatch(sourceUrl))
        'Adres źródła musi zaczynać się od https://.',
      if (!isPartner && !categories.contains(category))
        'Nieznana kategoria: $category.',
      if (status != draft && status != published) 'Nieznany status: $status.',
      if (isPartner && offer == null)
        'Ciekawostka partnerska musi mieć produkt, sklep i link.',
      if (isPartner && quiz != null)
        'Ciekawostka partnerska nie ma pytania quizowego.',
      ..._quizErrors(),
      ...?offer?.validationErrors(),
    ];
  }

  List<String> _quizErrors() {
    final quiz = this.quiz;
    if (quiz == null) return const [];

    return [
      if (quiz.question.trim().isEmpty) 'Brak pytania quizowego.',
      if (quiz.options.map((option) => option.trim()).toSet().length !=
          quizOptionCount)
        'Quiz musi mieć $quizOptionCount różne odpowiedzi.',
      if (quiz.correctIndex < 0 || quiz.correctIndex >= quizOptionCount)
        'Niepoprawny numer właściwej odpowiedzi.',
    ];
  }

  AdminFact copyWith({
    String? id,
    String? title,
    String? category,
    String? shortText,
    String? longText,
    String? sourceLabel,
    String? status,
    String? reviewNote,
  }) {
    return AdminFact(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      shortText: shortText ?? this.shortText,
      longText: longText ?? this.longText,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      sourceUrl: sourceUrl,
      status: status ?? this.status,
      quiz: quiz,
      reviewNote: reviewNote ?? this.reviewNote,
      offer: offer,
      hasOfferColumn: hasOfferColumn,
      kind: kind,
      hasKindColumn: hasKindColumn,
    );
  }

  /// Replaces the fields a form can change. Unlike [copyWith], this can clear
  /// the source address and the review note.
  AdminFact withEdits({
    required String title,
    required String category,
    required String shortText,
    required String longText,
    required String sourceLabel,
    required String? sourceUrl,
    required QuizQuestion? quiz,
    required String? reviewNote,
    required FactOffer? offer,
  }) {
    return AdminFact(
      id: id,
      title: title,
      category: category,
      shortText: shortText,
      longText: longText,
      sourceLabel: sourceLabel,
      sourceUrl: sourceUrl,
      status: status,
      quiz: quiz,
      reviewNote: reviewNote,
      offer: offer,
      hasOfferColumn: hasOfferColumn,
      kind: kind,
      hasKindColumn: hasKindColumn,
    );
  }

  /// Leaves `offer` and `kind` out when there is nothing to save and the
  /// database may not have the column yet, so the panel works before
  /// `supabase/offers.sql` and `supabase/partner_facts.sql`.
  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'title': title.trim(),
      'category': category,
      'short_text': shortText.trim(),
      'long_text': longText.trim(),
      'source_label': sourceLabel.trim(),
      'source_url': sourceUrl,
      'status': status,
      'quiz': quiz?.toJson(),
      'review_note': reviewNote,
      if (offer != null || hasOfferColumn) 'offer': offer?.toJson(),
      if (isPartner || hasKindColumn) 'kind': kind.name,
    };
  }
}
