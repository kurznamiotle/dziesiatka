/// How readers respond to a whole category, and how long its facts will last.
class CategoryPerformance {
  const CategoryPerformance({
    required this.category,
    required this.published,
    required this.drafts,
    required this.daysLeft,
    required this.shown,
    required this.liked,
    required this.opened,
  });

  final String category;
  final int published;
  final int drafts;

  /// Days of new facts for someone reading all categories evenly.
  final int daysLeft;
  final int shown;
  final int liked;
  final int opened;

  double? get likedPercent => shown == 0 ? null : 100 * liked / shown;

  double? get openedPercent => shown == 0 ? null : 100 * opened / shown;
}
