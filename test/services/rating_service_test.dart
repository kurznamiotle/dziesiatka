import 'package:dziesiatka/models/daily_deck.dart';
import 'package:dziesiatka/services/rating_service.dart';
import 'package:dziesiatka/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late int requests;
  late bool isAvailable;

  RatingService service({bool isSupported = true}) {
    DateTime clock() => now;
    return RatingService(
      StreakService(now: clock),
      now: clock,
      isSupported: isSupported,
      isAvailable: () async => isAvailable,
      requestReview: () async => requests++,
      openStoreListing: () async {},
    );
  }

  /// A user who started on [firstStart] and finished every day since then up
  /// to and including today.
  Future<void> finishDays({required DateTime firstStart}) async {
    final days = <String>[];
    for (
      var day = firstStart;
      !day.isAfter(now);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      days.add(_key(day));
    }
    SharedPreferences.setMockInitialValues({
      'ratingFirstStart': _key(firstStart),
      'streakDays': days,
    });
  }

  Future<bool> finishWithQuiz(int correct, {int total = 4}) {
    return service().requestReviewIfDue(quizCorrect: correct, quizTotal: total);
  }

  setUp(() {
    now = DateTime(2026, 11, 24, 19);
    requests = 0;
    isAvailable = true;
    SharedPreferences.setMockInitialValues({});
  });

  test('asks on the third finished day after a good quiz', () async {
    await finishDays(firstStart: DateTime(2026, 11, 22));

    expect(await finishWithQuiz(3), isTrue);
    expect(requests, 1);
  });

  test('waits for the third finished day', () async {
    await finishDays(firstStart: DateTime(2026, 11, 23));

    expect(await finishWithQuiz(4), isFalse);
    expect(requests, 0);
  });

  test('does not count days that were not finished', () async {
    SharedPreferences.setMockInitialValues({
      'ratingFirstStart': '2026-11-01',
      'streakDays': ['2026-11-01', '2026-11-10'],
    });

    expect(await finishWithQuiz(4), isFalse);
  });

  test('asks only when today itself is finished', () async {
    SharedPreferences.setMockInitialValues({
      'ratingFirstStart': '2026-11-01',
      'streakDays': ['2026-11-01', '2026-11-02', '2026-11-03'],
    });

    expect(await finishWithQuiz(4), isFalse);
  });

  test('does not ask after a weak quiz', () async {
    await finishDays(firstStart: DateTime(2026, 11, 20));

    expect(await finishWithQuiz(2), isFalse);
    expect(await finishWithQuiz(0, total: 0), isFalse);
    expect(requests, 0);
  });

  test('never asks in the first session', () async {
    SharedPreferences.setMockInitialValues({
      'streakDays': [for (var day = 20; day <= 24; day++) '2026-11-$day'],
    });
    final rating = service();

    await rating.recordAppStart();

    expect(
      await rating.requestReviewIfDue(quizCorrect: 4, quizTotal: 4),
      isFalse,
    );
    now = DateTime(2026, 11, 25, 19);
    await StreakService(now: () => now).recordCompletion();
    expect(
      await rating.requestReviewIfDue(quizCorrect: 4, quizTotal: 4),
      isTrue,
    );
  });

  test('a later start keeps the first one', () async {
    SharedPreferences.setMockInitialValues({'ratingFirstStart': '2026-11-01'});

    await service().recordAppStart();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ratingFirstStart'), '2026-11-01');
  });

  test('stays quiet on a day with another prompt', () async {
    await finishDays(firstStart: DateTime(2026, 11, 20));
    final rating = service();

    await rating.recordOtherPrompt();

    expect(
      await rating.requestReviewIfDue(quizCorrect: 4, quizTotal: 4),
      isFalse,
    );
    expect(requests, 0);
  });

  test('asks again only after 60 days', () async {
    await finishDays(firstStart: DateTime(2026, 11, 20));
    expect(await finishWithQuiz(4), isTrue);

    final prefs = await SharedPreferences.getInstance();
    Future<bool> finishOn(DateTime day) async {
      now = day;
      await prefs.setStringList('streakDays', [
        ...prefs.getStringList('streakDays')!,
        _key(day),
      ]);
      return finishWithQuiz(4);
    }

    expect(await finishOn(DateTime(2026, 11, 25, 19)), isFalse);
    expect(await finishOn(DateTime(2027, 1, 22, 19)), isFalse);
    expect(await finishOn(DateTime(2027, 1, 23, 19)), isTrue);
    expect(requests, 2);
  });

  test('stops after 3 requests', () async {
    await finishDays(firstStart: DateTime(2026, 1, 1));
    SharedPreferences.setMockInitialValues({
      'ratingFirstStart': '2026-01-01',
      'streakDays': (await SharedPreferences.getInstance()).getStringList(
        'streakDays',
      )!,
      'ratingRequests': ['2026-03-01', '2026-06-01', '2026-09-01'],
    });

    expect(await finishWithQuiz(4), isFalse);
    expect(requests, 0);
  });

  test('a third request is still allowed', () async {
    await finishDays(firstStart: DateTime(2026, 1, 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('ratingRequests', ['2026-03-01', '2026-06-01']);

    expect(await finishWithQuiz(4), isTrue);
    expect(prefs.getStringList('ratingRequests'), hasLength(3));
  });

  test('does not count a request when the flow is unavailable', () async {
    await finishDays(firstStart: DateTime(2026, 11, 20));
    isAvailable = false;

    expect(await finishWithQuiz(4), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('ratingRequests'), isNull);
  });

  test('never asks on the web', () async {
    await finishDays(firstStart: DateTime(2026, 11, 20));
    final rating = service(isSupported: false);

    expect(
      await rating.requestReviewIfDue(quizCorrect: 4, quizTotal: 4),
      isFalse,
    );
    expect(await rating.openStoreListing(), isFalse);
    expect(requests, 0);
  });

  test('opens the store listing on Android', () async {
    expect(await service().openStoreListing(), isTrue);
  });
}

String _key(DateTime day) => DailyDeck.dateKey(day);
