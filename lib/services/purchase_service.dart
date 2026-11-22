import 'dart:async';

import 'package:dziesiatka/models/purchase_outcome.dart';
import 'package:dziesiatka/models/store_product.dart';
import 'package:dziesiatka/models/store_purchase.dart';
import 'package:dziesiatka/services/in_app_purchase_gateway.dart';
import 'package:dziesiatka/services/store_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dziesiątka+ and tips, bought through the app store. Whatever the store does
/// not return stays hidden: a product not yet created in the Play Console, the
/// web version and a phone without a connection all show nothing to buy.
class PurchaseService extends ChangeNotifier {
  PurchaseService({StoreGateway? store}) : _store = store;

  /// The store only on Android. The App Store gets the same products once
  /// they exist there, as the code does not depend on the platform.
  factory PurchaseService.forPlatform() {
    final hasStore = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return PurchaseService(store: hasStore ? InAppPurchaseGateway() : null);
  }

  static const plusId = 'dziesiatka_plus';
  static const tipIds = ['napiwek_maly', 'napiwek_sredni', 'napiwek_duzy'];
  static const _plusKey = 'plusOwned';

  final StoreGateway? _store;
  StreamSubscription<List<StorePurchase>>? _subscription;
  final _outcomes = StreamController<PurchaseOutcome>.broadcast();

  bool _hasPlus = false;
  bool _isPlusPending = false;
  bool _isTipPending = false;
  StoreProduct? _plusProduct;
  List<StoreProduct> _tips = const [];

  bool get hasPlus => _hasPlus;
  bool get isPlusPending => _isPlusPending;
  bool get isTipPending => _isTipPending;

  /// Null until the store returns the product, which is the switch that keeps
  /// Dziesiątka+ hidden.
  StoreProduct? get plusProduct => _plusProduct;

  /// The tips the store returned, smallest first.
  List<StoreProduct> get tips => _tips;

  /// An owner keeps seeing it even offline, to know what they have.
  bool get showsPlus => _hasPlus || _plusProduct != null;

  bool get hasTips => _tips.isNotEmpty;

  /// What purchases end with, for thanks and celebrations.
  Stream<PurchaseOutcome> get outcomes => _outcomes.stream;

  /// Reads what this device already owns. Fast and offline, so the app can
  /// start with the right colors.
  Future<void> loadOwned() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasPlus = prefs.getBool(_plusKey) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  /// Talks to the store behind the scenes, so the app never waits for it.
  /// On Android it also asks for owned products, which brings purchases that
  /// finished while the app was closed, such as a pending payment, so they get
  /// acknowledged in time.
  Future<void> connect() async {
    final store = _store;
    if (store == null) return;

    try {
      if (!await store.isAvailable()) return;
      _subscription ??= store.purchases.listen(_onPurchases);
      final products = await store.loadProducts({plusId, ...tipIds});
      _plusProduct = products.where((item) => item.id == plusId).firstOrNull;
      _tips = [
        for (final id in tipIds) ...products.where((item) => item.id == id),
      ];
      notifyListeners();
      await store.restore();
    } catch (_) {
      // Without the store nothing is shown, and the next start tries again.
    }
  }

  Future<bool> buyPlus() async {
    if (_hasPlus || _plusProduct == null) return false;
    return _buy(plusId, isConsumable: false);
  }

  Future<bool> buyTip(String id) async {
    if (!_tips.any((item) => item.id == id)) return false;
    return _buy(id, isConsumable: true);
  }

  /// Owned Dziesiątka+ comes back through [outcomes].
  Future<void> restore() async {
    try {
      await _store?.restore();
    } catch (_) {
      _outcomes.add(PurchaseOutcome.failed);
    }
  }

  Future<bool> _buy(String id, {required bool isConsumable}) async {
    try {
      final started = await _store!.buy(id, isConsumable: isConsumable);
      if (!started) _outcomes.add(PurchaseOutcome.failed);
      return started;
    } catch (_) {
      _outcomes.add(PurchaseOutcome.failed);
      return false;
    }
  }

  Future<void> _onPurchases(List<StorePurchase> purchases) async {
    for (final purchase in purchases) {
      try {
        await _handle(purchase);
      } catch (_) {
        // An unfinished purchase comes back from the store on the next start.
      }
    }
  }

  Future<void> _handle(StorePurchase purchase) async {
    final isPlus = purchase.productId == plusId;
    final isTip = tipIds.contains(purchase.productId);
    if (!isPlus && !isTip) return;

    switch (purchase.status) {
      case StorePurchaseStatus.pending:
        if (isPlus) {
          _isPlusPending = true;
        } else {
          _isTipPending = true;
        }
        notifyListeners();
        _outcomes.add(
          isPlus ? PurchaseOutcome.plusPending : PurchaseOutcome.tipPending,
        );
      case StorePurchaseStatus.purchased || StorePurchaseStatus.restored:
        if (isPlus) {
          await _grantPlus(
            wasRestored: purchase.status == StorePurchaseStatus.restored,
          );
        } else {
          _isTipPending = false;
          notifyListeners();
          _outcomes.add(PurchaseOutcome.tipThanks);
        }
        // Saved first, so a failed confirmation never loses what was paid.
        await _store!.finish(purchase, consume: isTip);
      case StorePurchaseStatus.canceled || StorePurchaseStatus.error:
        if (isPlus) _isPlusPending = false;
        if (isTip) _isTipPending = false;
        notifyListeners();
        if (purchase.status == StorePurchaseStatus.error) {
          _outcomes.add(PurchaseOutcome.failed);
        }
        if (purchase.needsCompletion) {
          await _store!.finish(purchase, consume: false);
        }
    }
  }

  /// A restore at every start sends owned products again, which must not
  /// celebrate each time.
  Future<void> _grantPlus({required bool wasRestored}) async {
    final isNew = !_hasPlus;
    _hasPlus = true;
    _isPlusPending = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_plusKey, true);
    } catch (_) {}
    if (!isNew) return;
    _outcomes.add(
      wasRestored
          ? PurchaseOutcome.plusRestored
          : PurchaseOutcome.plusPurchased,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _outcomes.close();
    super.dispose();
  }
}
