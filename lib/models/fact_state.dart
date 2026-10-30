/// What this user has done with a fact. It stays on the device, apart from the
/// content, which can change on the server.
class FactState {
  const FactState({
    this.isRead = false,
    this.isFavorite = false,
    this.lastReadAt,
  });

  factory FactState.fromJson(Map<String, dynamic> json) {
    final lastReadAt = json['lastReadAt'] as String?;
    return FactState(
      isRead: json['isRead'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastReadAt: lastReadAt == null ? null : DateTime.parse(lastReadAt),
    );
  }

  final bool isRead;
  final bool isFavorite;

  /// When the fact was last read, or null if never or before dates were saved.
  final DateTime? lastReadAt;

  bool get isDefault => !isRead && !isFavorite && lastReadAt == null;

  Map<String, dynamic> toJson() {
    return {
      'isRead': isRead,
      'isFavorite': isFavorite,
      'lastReadAt': lastReadAt?.toIso8601String(),
    };
  }
}
