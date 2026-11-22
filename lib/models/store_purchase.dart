enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

/// One update about a purchase from the store.
class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.needsCompletion = false,
    this.handle,
  });

  final String productId;
  final StorePurchaseStatus status;

  /// The store waits for the app to confirm it. Google refunds a purchase that
  /// is not acknowledged within 3 days.
  final bool needsCompletion;

  /// The store's own object, passed back to it when the purchase is finished.
  final Object? handle;

  bool get isSuccessful {
    return status == StorePurchaseStatus.purchased ||
        status == StorePurchaseStatus.restored;
  }
}
