import 'package:dziesiatka/models/store_product.dart';
import 'package:dziesiatka/models/store_purchase.dart';

/// The app store as [PurchaseService] needs it, so tests can use a fake one.
abstract interface class StoreGateway {
  Future<bool> isAvailable();

  /// Returns only the products the store knows. One not yet created in the
  /// Play Console is left out.
  Future<List<StoreProduct>> loadProducts(Set<String> ids);

  Stream<List<StorePurchase>> get purchases;

  /// Starts the store's payment sheet. The result arrives on [purchases].
  Future<bool> buy(String productId, {required bool isConsumable});

  /// Asks the store to send owned products to [purchases] again.
  Future<void> restore();

  /// Confirms a delivered purchase. A consumable one is used up as well, so
  /// it can be bought again.
  Future<void> finish(StorePurchase purchase, {required bool consume});
}
