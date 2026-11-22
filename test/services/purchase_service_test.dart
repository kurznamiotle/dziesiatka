import 'package:dziesiatka/models/purchase_outcome.dart';
import 'package:dziesiatka/models/store_purchase.dart';
import 'package:dziesiatka/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeStore store;
  late PurchaseService service;
  late List<PurchaseOutcome> outcomes;

  Future<void> connect() async {
    service = PurchaseService(store: store);
    service.outcomes.listen(outcomes.add);
    await service.loadOwned();
    await service.connect();
    await pumpEventQueue();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = FakeStore();
    outcomes = [];
    service = PurchaseService();
  });

  tearDown(() => service.dispose());

  group('products', () {
    test('come with prices from the store', () async {
      await connect();

      expect(service.showsPlus, isTrue);
      expect(service.plusProduct?.price, '14,99 zł');
      expect(service.tips.map((tip) => tip.id), PurchaseService.tipIds);
    });

    test('a product missing in the console hides Dziesiątka+', () async {
      store.products = {...PurchaseService.tipIds};
      await connect();

      expect(service.plusProduct, isNull);
      expect(service.showsPlus, isFalse);
      expect(await service.buyPlus(), isFalse);
      expect(store.bought, isEmpty);
    });

    test('missing tips hide the tips', () async {
      store.products = {PurchaseService.plusId};
      await connect();

      expect(service.hasTips, isFalse);
    });

    test('a store that is not available shows nothing', () async {
      store.isOnline = false;
      await connect();

      expect(service.showsPlus, isFalse);
      expect(service.hasTips, isFalse);
    });

    test('without a store, as on the web, nothing is shown', () async {
      await service.loadOwned();
      await service.connect();

      expect(service.showsPlus, isFalse);
      expect(service.hasTips, isFalse);
    });
  });

  group('Dziesiątka+', () {
    test('a purchase unlocks it, is saved and acknowledged', () async {
      await connect();

      expect(await service.buyPlus(), isTrue);
      store.complete(PurchaseService.plusId);
      await pumpEventQueue();

      expect(service.hasPlus, isTrue);
      expect(outcomes, [PurchaseOutcome.plusPurchased]);
      expect(store.finished.single, (
        productId: PurchaseService.plusId,
        consumed: false,
      ));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('plusOwned'), isTrue);
    });

    test('it stays after a restart without the store', () async {
      SharedPreferences.setMockInitialValues({'plusOwned': true});
      store.isOnline = false;
      await connect();

      expect(service.hasPlus, isTrue);
      expect(service.showsPlus, isTrue);
    });

    test('restoring brings it back on a new device', () async {
      await connect();
      store.owned.add(PurchaseService.plusId);

      await service.restore();
      await pumpEventQueue();

      expect(service.hasPlus, isTrue);
      expect(outcomes, [PurchaseOutcome.plusRestored]);
      expect(store.finished.single.productId, PurchaseService.plusId);
    });

    test('a later restore does not celebrate again', () async {
      store.owned.add(PurchaseService.plusId);
      await connect();
      expect(outcomes, [PurchaseOutcome.plusRestored]);

      await service.restore();
      await pumpEventQueue();

      expect(outcomes, [PurchaseOutcome.plusRestored]);
    });

    test('a pending payment waits and is granted when it clears', () async {
      await connect();
      await service.buyPlus();

      store.complete(
        PurchaseService.plusId,
        status: StorePurchaseStatus.pending,
      );
      await pumpEventQueue();

      expect(service.hasPlus, isFalse);
      expect(service.isPlusPending, isTrue);
      expect(store.finished, isEmpty);

      store.complete(PurchaseService.plusId);
      await pumpEventQueue();

      expect(service.hasPlus, isTrue);
      expect(service.isPlusPending, isFalse);
      expect(outcomes, [
        PurchaseOutcome.plusPending,
        PurchaseOutcome.plusPurchased,
      ]);
      expect(store.finished, hasLength(1));
    });

    test(
      'a payment cleared while the app was closed is acknowledged',
      () async {
        store.owned.add(PurchaseService.plusId);

        await connect();

        expect(store.restores, 1);
        expect(service.hasPlus, isTrue);
        expect(store.finished.single.productId, PurchaseService.plusId);
      },
    );

    test('a cancelled payment changes nothing', () async {
      await connect();
      await service.buyPlus();

      store.complete(
        PurchaseService.plusId,
        status: StorePurchaseStatus.canceled,
      );
      await pumpEventQueue();

      expect(service.hasPlus, isFalse);
      expect(outcomes, isEmpty);
    });

    test('cannot be bought twice', () async {
      SharedPreferences.setMockInitialValues({'plusOwned': true});
      await connect();

      expect(await service.buyPlus(), isFalse);
    });
  });

  group('tips', () {
    test('a tip is consumed, so it can be bought again', () async {
      await connect();

      expect(await service.buyTip('napiwek_sredni'), isTrue);
      store.complete('napiwek_sredni');
      await pumpEventQueue();

      expect(store.finished.single, (
        productId: 'napiwek_sredni',
        consumed: true,
      ));
      expect(store.owned, isEmpty);
      expect(outcomes, [PurchaseOutcome.tipThanks]);
      expect(service.hasPlus, isFalse);

      expect(await service.buyTip('napiwek_sredni'), isTrue);
      expect(store.bought, ['napiwek_sredni', 'napiwek_sredni']);
    });

    test('an unconsumed tip from before a restart is consumed', () async {
      store.owned.add('napiwek_duzy');

      await connect();

      expect(store.finished.single, (
        productId: 'napiwek_duzy',
        consumed: true,
      ));
    });

    test('an unknown tip is not bought', () async {
      await connect();

      expect(await service.buyTip('napiwek_ogromny'), isFalse);
    });
  });
}
