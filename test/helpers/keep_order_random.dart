import 'dart:math';

/// Leaves a list in its order when it is shuffled, so a test can name the
/// cards it expects.
class KeepOrderRandom implements Random {
  const KeepOrderRandom();

  @override
  int nextInt(int max) => max - 1;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
