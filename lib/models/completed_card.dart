/// A card finished today, with the state it had before, so undo can restore it.
class CompletedCard {
  const CompletedCard({
    required this.factId,
    required this.wasRead,
    required this.wasFavorite,
  });

  factory CompletedCard.fromJson(Map<String, dynamic> json) {
    return CompletedCard(
      factId: json['factId'] as String,
      wasRead: json['wasRead'] as bool,
      wasFavorite: json['wasFavorite'] as bool,
    );
  }

  final String factId;
  final bool wasRead;
  final bool wasFavorite;

  Map<String, dynamic> toJson() {
    return {'factId': factId, 'wasRead': wasRead, 'wasFavorite': wasFavorite};
  }
}
