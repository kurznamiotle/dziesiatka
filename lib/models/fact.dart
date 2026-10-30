class Fact {
  const Fact({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String title;
  final String content;
  final String category;
  final bool isRead;
  final DateTime createdAt;

  Fact copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Fact(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
