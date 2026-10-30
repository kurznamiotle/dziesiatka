import 'package:dziesiatka/models/quiz_question.dart';

class Fact {
  const Fact({
    required this.id,
    required this.title,
    required this.category,
    required this.shortText,
    required this.longText,
    required this.source,
    required this.createdAt,
    this.isRead = false,
    this.isFavorite = false,
    this.lastReadAt,
    this.quiz,
  });

  /// Facts saved before the split into [shortText] and [longText] have a single
  /// `content` field and no `source`, so both fall back here.
  factory Fact.fromJson(Map<String, dynamic> json) {
    final legacyContent = json['content'] as String?;
    final quiz = json['quiz'] as Map<String, dynamic>?;
    final lastReadAt = json['lastReadAt'] as String?;
    return Fact(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortText: json['shortText'] as String? ?? legacyContent!,
      longText: json['longText'] as String? ?? legacyContent!,
      source: json['source'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastReadAt: lastReadAt == null ? null : DateTime.parse(lastReadAt),
      quiz: quiz == null ? null : QuizQuestion.fromJson(quiz),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String title;
  final String category;
  final String shortText;
  final String longText;
  final String source;
  final bool isRead;
  final bool isFavorite;

  /// When the fact was last read, or null if never or before dates were saved.
  final DateTime? lastReadAt;
  final QuizQuestion? quiz;
  final DateTime createdAt;

  Fact copyWith({
    String? id,
    String? title,
    String? category,
    String? shortText,
    String? longText,
    String? source,
    bool? isRead,
    bool? isFavorite,
    DateTime? lastReadAt,
    QuizQuestion? quiz,
    DateTime? createdAt,
  }) {
    return Fact(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      shortText: shortText ?? this.shortText,
      longText: longText ?? this.longText,
      source: source ?? this.source,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      quiz: quiz ?? this.quiz,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Sets all reading state at once. Unlike [copyWith], this can clear
  /// [lastReadAt], which undo needs for a fact read for the first time.
  Fact withCardState({
    required bool isRead,
    required bool isFavorite,
    required DateTime? lastReadAt,
  }) {
    return Fact(
      id: id,
      title: title,
      category: category,
      shortText: shortText,
      longText: longText,
      source: source,
      isRead: isRead,
      isFavorite: isFavorite,
      lastReadAt: lastReadAt,
      quiz: quiz,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'shortText': shortText,
      'longText': longText,
      'source': source,
      'isRead': isRead,
      'isFavorite': isFavorite,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'quiz': quiz?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
