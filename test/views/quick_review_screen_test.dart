import 'package:dziesiatka/views/quick_review_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('praises at least half of the answers right', () {
    expect(QuickReviewScreen.resultMessage(3, 3), '3/3 – pamięć działa!');
    expect(QuickReviewScreen.resultMessage(2, 3), '2/3 – pamięć działa!');
    expect(QuickReviewScreen.resultMessage(1, 2), '1/2 – pamięć działa!');
  });

  test('encourages after fewer right answers', () {
    expect(
      QuickReviewScreen.resultMessage(1, 3),
      '1/3 – następnym razem pójdzie lepiej!',
    );
  });
}
