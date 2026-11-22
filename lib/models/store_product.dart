/// A product as the store describes it. The price comes formatted by the
/// store, in the user's currency, and is never set in the app.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
    this.rawPrice = 0,
  });

  final String id;
  final String title;

  /// Ready to show, such as „9,99 zł”.
  final String price;

  /// For sorting only.
  final double rawPrice;
}
