import 'package:dziesiatka/models/fact_state.dart';
import 'package:dziesiatka/models/quiz_question.dart';

/// A fact's content together with this user's [state]. Only the content is
/// serialized, because the state is stored apart from it.
class Fact {
  const Fact({
    required this.id,
    required this.title,
    required this.category,
    required this.shortText,
    required this.longText,
    required this.sourceLabel,
    required this.createdAt,
    DateTime? updatedAt,
    this.sourceUrl,
    this.isWithdrawn = false,
    this.isRead = false,
    this.isFavorite = false,
    this.lastReadAt,
    this.quiz,
  }) : updatedAt = updatedAt ?? createdAt;

  /// Reads the app's own format. Facts saved before the split into [shortText]
  /// and [longText] have a single `content` field, and those saved before the
  /// split into [sourceLabel] and [sourceUrl] have a `source` field.
  factory Fact.fromJson(Map<String, dynamic> json) {
    final legacyContent = json['content'] as String?;
    final quiz = json['quiz'] as Map<String, dynamic>?;
    final updatedAt = json['updatedAt'] as String?;
    return Fact(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortText: json['shortText'] as String? ?? legacyContent!,
      longText: json['longText'] as String? ?? legacyContent!,
      sourceLabel:
          json['sourceLabel'] as String? ?? json['source'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String?,
      isWithdrawn: json['isWithdrawn'] as bool? ?? false,
      quiz: quiz == null ? null : QuizQuestion.fromJson(quiz),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt),
    );
  }

  /// Reads a row of the `facts` table from Supabase.
  factory Fact.fromRow(Map<String, dynamic> row) {
    final quiz = row['quiz'] as Map<String, dynamic>?;
    return Fact(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      shortText: row['short_text'] as String,
      longText: row['long_text'] as String,
      sourceLabel: row['source_label'] as String,
      sourceUrl: row['source_url'] as String?,
      isWithdrawn: row['status'] == 'withdrawn',
      quiz: quiz == null ? null : QuizQuestion.fromJson(quiz),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  final String id;
  final String title;
  final String category;
  final String shortText;
  final String longText;
  final String sourceLabel;

  /// Where [sourceLabel] links to, for sources that are on the web.
  final String? sourceUrl;

  /// Taken out of circulation. A withdrawn fact stays in a deck that already
  /// has it, so today's progress survives, but no new deck picks it.
  final bool isWithdrawn;
  final bool isRead;
  final bool isFavorite;

  /// When the fact was last read, or null if never or before dates were saved.
  final DateTime? lastReadAt;
  final QuizQuestion? quiz;
  final DateTime createdAt;

  /// Decides which copy of a fact is newer when two sources have it.
  final DateTime updatedAt;

  FactState get state {
    return FactState(
      isRead: isRead,
      isFavorite: isFavorite,
      lastReadAt: lastReadAt,
    );
  }

  Fact copyWith({
    String? id,
    String? title,
    String? category,
    String? shortText,
    String? longText,
    String? sourceLabel,
    String? sourceUrl,
    bool? isWithdrawn,
    bool? isRead,
    bool? isFavorite,
    DateTime? lastReadAt,
    QuizQuestion? quiz,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fact(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      shortText: shortText ?? this.shortText,
      longText: longText ?? this.longText,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isWithdrawn: isWithdrawn ?? this.isWithdrawn,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      quiz: quiz ?? this.quiz,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Replaces all reading state at once. Unlike [copyWith], this can clear
  /// [lastReadAt], which undo needs for a fact read for the first time.
  Fact withState(FactState state) {
    return Fact(
      id: id,
      title: title,
      category: category,
      shortText: shortText,
      longText: longText,
      sourceLabel: sourceLabel,
      sourceUrl: sourceUrl,
      isWithdrawn: isWithdrawn,
      isRead: state.isRead,
      isFavorite: state.isFavorite,
      lastReadAt: state.lastReadAt,
      quiz: quiz,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'shortText': shortText,
      'longText': longText,
      'sourceLabel': sourceLabel,
      'sourceUrl': sourceUrl,
      'isWithdrawn': isWithdrawn,
      'quiz': quiz?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
