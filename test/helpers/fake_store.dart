import 'dart:async';

import 'package:dziesiatka/models/store_product.dart';
import 'package:dziesiatka/models/store_purchase.dart';
import 'package:dziesiatka/services/purchase_service.dart';
import 'package:dziesiatka/services/store_gateway.dart';

/// A store whose products and answers a test decides.
class FakeStore implements StoreGateway {
  FakeStore({Set<String>? products, this.isOnline = true})
    : products =
          products ?? {PurchaseService.plusId, ...PurchaseService.tipIds};

  /// The products created in the console.
  Set<String> products;
  bool isOnline;

  /// Products the account owns, sent again by [restore].
  final owned = <String>{};
  final bought = <String>[];
  final finished = <({String productId, bool consumed})>[];
  int restores = 0;
  final _purchases = StreamController<List<StorePurchase>>.broadcast();

  static const prices = {
    PurchaseService.plusId: '14,99 zł',
    'napiwek_maly': '5,00 zł',
    'napiwek_sredni': '10,00 zł',
    'napiwek_duzy': '20,00 zł',
  };

  @override
  Future<bool> isAvailable() async => isOnline;

  /// Returns them in reverse, as a store may use any order.
  @override
  Future<List<StoreProduct>> loadProducts(Set<String> ids) async {
    return [
      for (final id in ids.where(products.contains).toList().reversed)
        StoreProduct(id: id, title: id, price: prices[id] ?? '1,00 zł'),
    ];
  }

  @override
  Stream<List<StorePurchase>> get purchases => _purchases.stream;

  /// Leaves the purchase waiting, as the user picks the payment.
  @override
  Future<bool> buy(String productId, {required bool isConsumable}) async {
    bought.add(productId);
    return true;
  }

  @override
  Future<void> restore() async {
    restores++;
    send([
      for (final id in owned)
        StorePurchase(
          productId: id,
          status: StorePurchaseStatus.restored,
          needsCompletion: true,
        ),
    ]);
  }

  @override
  Future<void> finish(StorePurchase purchase, {required bool consume}) async {
    finished.add((productId: purchase.productId, consumed: consume));
    if (consume) owned.remove(purchase.productId);
  }

  void send(List<StorePurchase> purchases) {
    if (purchases.isNotEmpty) _purchases.add(purchases);
  }

  /// The store reports [id] with [status], as after the payment sheet.
  void complete(
    String id, {
    StorePurchaseStatus status = StorePurchaseStatus.purchased,
  }) {
    if (status == StorePurchaseStatus.purchased) owned.add(id);
    send([StorePurchase(productId: id, status: status, needsCompletion: true)]);
  }
}
