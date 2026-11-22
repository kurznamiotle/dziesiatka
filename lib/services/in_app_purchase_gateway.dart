import 'package:dziesiatka/models/store_product.dart';
import 'package:dziesiatka/models/store_purchase.dart';
import 'package:dziesiatka/services/store_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Google Play and the App Store through the `in_app_purchase` plugin.
class InAppPurchaseGateway implements StoreGateway {
  InAppPurchaseGateway([InAppPurchase? store])
    : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final _details = <String, ProductDetails>{};

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> isAvailable() => _store.isAvailable();

  @override
  Future<List<StoreProduct>> loadProducts(Set<String> ids) async {
    final response = await _store.queryProductDetails(ids);
    for (final details in response.productDetails) {
      _details[details.id] = details;
    }
    return [
      for (final details in response.productDetails)
        StoreProduct(
          id: details.id,
          title: details.title,
          price: details.price,
          rawPrice: details.rawPrice,
        ),
    ];
  }

  @override
  Stream<List<StorePurchase>> get purchases {
    return _store.purchaseStream.map(
      (items) => [for (final item in items) _purchaseOf(item)],
    );
  }

  StorePurchase _purchaseOf(PurchaseDetails details) {
    return StorePurchase(
      productId: details.productID,
      status: switch (details.status) {
        PurchaseStatus.pending => StorePurchaseStatus.pending,
        PurchaseStatus.purchased => StorePurchaseStatus.purchased,
        PurchaseStatus.restored => StorePurchaseStatus.restored,
        PurchaseStatus.canceled => StorePurchaseStatus.canceled,
        PurchaseStatus.error => StorePurchaseStatus.error,
      },
      needsCompletion: details.pendingCompletePurchase,
      handle: details,
    );
  }

  @override
  Future<bool> buy(String productId, {required bool isConsumable}) async {
    final details = _details[productId];
    if (details == null) return false;

    final param = PurchaseParam(productDetails: details);
    // Consumed by finish, also for a purchase that arrives after a restart.
    return isConsumable
        ? _store.buyConsumable(purchaseParam: param, autoConsume: false)
        : _store.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> restore() => _store.restorePurchases();

  /// On Android consuming also acknowledges, so only one of them runs.
  @override
  Future<void> finish(StorePurchase purchase, {required bool consume}) async {
    final details = purchase.handle;
    if (details is! PurchaseDetails) return;

    if (consume && _isAndroid) {
      await _store
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .consumePurchase(details);
      return;
    }
    if (details.pendingCompletePurchase) {
      await _store.completePurchase(details);
    }
  }
}
