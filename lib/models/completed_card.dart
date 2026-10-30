/// A card finished today, with the state it had before, so undo can restore it.
class CompletedCard {
  const CompletedCard({
    required this.factId,
    required this.wasRead,
    required this.wasFavorite,
    this.previousLastReadAt,
  });

  factory CompletedCard.fromJson(Map<String, dynamic> json) {
    final previousLastReadAt = json['previousLastReadAt'] as String?;
    return CompletedCard(
      factId: json['factId'] as String,
      wasRead: json['wasRead'] as bool,
      wasFavorite: json['wasFavorite'] as bool,
      previousLastReadAt: previousLastReadAt == null
          ? null
          : DateTime.parse(previousLastReadAt),
    );
  }

  final String factId;
  final bool wasRead;
  final bool wasFavorite;
  final DateTime? previousLastReadAt;

  Map<String, dynamic> toJson() {
    return {
      'factId': factId,
      'wasRead': wasRead,
      'wasFavorite': wasFavorite,
      'previousLastReadAt': previousLastReadAt?.toIso8601String(),
    };
  }
}
