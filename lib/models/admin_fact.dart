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
  });

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
      if (!categories.contains(category)) 'Nieznana kategoria: $category.',
      if (status != draft && status != published) 'Nieznany status: $status.',
      ..._quizErrors(),
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
    );
  }

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
    };
  }
}
