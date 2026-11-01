import 'package:dziesiatka/models/celebration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Celebration dayWith(int correct, {int total = 4, int streak = 1}) {
    return Celebration.forDay(
      quizCorrect: correct,
      quizTotal: total,
      streak: streak,
    );
  }

  test('the headline and intensity follow the quiz score', () {
    expect(dayWith(1).headline, 'Dobra robota!');
    expect(dayWith(1).intensity, 0);
    expect(dayWith(2).headline, 'Super!');
    expect(dayWith(2).intensity, 1);
    expect(dayWith(4).headline, 'WOW!');
    expect(dayWith(4).intensity, 2);
  });

  test('a streak milestone adds intensity and a message', () {
    final milestone = dayWith(2, streak: 10);

    expect(milestone.intensity, 2);
    expect(milestone.message, 'Seria 10 dni! Tak trzymać!');
  });

  test('a big milestone adds more than a small one', () {
    expect(dayWith(1, streak: 5).intensity, 1);
    expect(dayWith(1, streak: 25).intensity, 2);
  });

  test('intensity never passes the maximum', () {
    expect(dayWith(4, streak: 50).intensity, Celebration.maxIntensity);
  });

  test('other streaks have no message', () {
    expect(dayWith(4, streak: 7).message, isNull);
  });

  test('a deck without a quiz is calm', () {
    final day = Celebration.forDay(quizCorrect: null, quizTotal: 0, streak: 3);

    expect(day.headline, 'Dobra robota!');
    expect(day.intensity, 0);
  });
}
