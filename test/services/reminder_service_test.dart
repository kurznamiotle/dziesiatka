import 'package:dziesiatka/services/reminder_scheduler.dart';
import 'package:dziesiatka/services/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeScheduler implements ReminderScheduler {
  _FakeScheduler({this.isSupported = true, this.allows = true});

  @override
  final bool isSupported;
  final bool allows;
  List<DateTime> planned = [];
  int replaceCount = 0;

  @override
  Future<bool> requestPermission() async => allows;

  @override
  Future<void> replaceAll(List<DateTime> times) async {
    planned = times;
    replaceCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeScheduler scheduler;
  late DateTime now;
  late ReminderService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    scheduler = _FakeScheduler();
    now = DateTime(2026, 11, 2, 9);
    service = ReminderService(scheduler: scheduler, now: () => now);
  });

  test('an unfinished day is reminded of today at 18:00', () async {
    await service.update(isDayFinished: false);

    expect(scheduler.planned.first, DateTime(2026, 11, 2, 18));
    expect(scheduler.planned, hasLength(ReminderService.daysAhead));
  });

  test(
    'a finished day has no reminder today but keeps the next ones',
    () async {
      await service.update(isDayFinished: false);
      await service.update(isDayFinished: true);

      expect(scheduler.planned.first, DateTime(2026, 11, 3, 18));
      expect(scheduler.planned, hasLength(ReminderService.daysAhead));
    },
  );

  test('after 18:00 the first reminder is tomorrow', () async {
    now = DateTime(2026, 11, 2, 18);

    await service.update(isDayFinished: false);

    expect(scheduler.planned.first, DateTime(2026, 11, 3, 18));
  });

  test('stays at 18:00 across the month and year end', () async {
    now = DateTime(2026, 12, 25, 9);

    await service.update(isDayFinished: false);

    expect(scheduler.planned.last, DateTime(2027, 1, 7, 18));
  });

  test('the same state on the same day is not planned twice', () async {
    await service.update(isDayFinished: false);
    await service.update(isDayFinished: false);

    expect(scheduler.replaceCount, 1);
  });

  test('a new day plans again', () async {
    await service.update(isDayFinished: true);
    now = now.add(const Duration(days: 1));

    await service.update(isDayFinished: false);

    expect(scheduler.replaceCount, 2);
    expect(scheduler.planned.first, DateTime(2026, 11, 3, 18));
  });

  test('turning reminders off removes the planned ones', () async {
    await service.update(isDayFinished: false);

    expect(await service.setEnabled(false), isFalse);

    expect(scheduler.planned, isEmpty);
    expect(await service.isEnabled(), isFalse);
  });

  test('without the permission reminders stay off', () async {
    final refused = ReminderService(
      scheduler: _FakeScheduler(allows: false),
      now: () => now,
    );

    expect(await refused.setEnabled(true), isFalse);
    expect(await refused.isEnabled(), isFalse);
  });

  test('does nothing where reminders are not supported', () async {
    final web = _FakeScheduler(isSupported: false);
    final service = ReminderService(scheduler: web, now: () => now);

    await service.update(isDayFinished: false);

    expect(service.isSupported, isFalse);
    expect(web.replaceCount, 0);
  });
}
