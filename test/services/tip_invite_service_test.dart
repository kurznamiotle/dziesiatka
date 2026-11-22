import 'package:dziesiatka/services/tip_invite_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late TipInviteService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 22, 18);
    service = TipInviteService(now: () => now);
  });

  test('waits for the 7th day of the streak', () async {
    expect(await service.claimForToday(streak: 6, hasTips: true), isFalse);
    expect(await service.claimForToday(streak: 7, hasTips: true), isTrue);
  });

  test('needs tips from the store', () async {
    expect(await service.claimForToday(streak: 9, hasTips: false), isFalse);
  });

  test('stays for the rest of that day', () async {
    await service.claimForToday(streak: 7, hasTips: true);
    now = now.add(const Duration(hours: 3));

    expect(await service.claimForToday(streak: 7, hasTips: true), isTrue);
  });

  test('never shows again on a later day', () async {
    await service.claimForToday(streak: 7, hasTips: true);

    now = now.add(const Duration(days: 1));
    expect(await service.claimForToday(streak: 8, hasTips: true), isFalse);
    now = now.add(const Duration(days: 30));
    expect(await service.claimForToday(streak: 38, hasTips: true), isFalse);
  });

  test('closing ends it at once, also on the same day', () async {
    await service.claimForToday(streak: 7, hasTips: true);

    await service.close();

    expect(await service.claimForToday(streak: 7, hasTips: true), isFalse);
  });

  test('a tip before the 7th day means it never shows', () async {
    await service.close();

    expect(await service.claimForToday(streak: 7, hasTips: true), isFalse);
  });
}
