import 'dart:math';

class Randomizer {
  static final Random _randomInRange = Random();

  // Will throw RangeError if max is not positive and <= 2^32: Not in inclusive
  // range 1.
  static int nextIntInRange(int min, int max) {
    int result = min + _randomInRange.nextInt(max - min);
    return result;
  }
}
