import 'dart:math';

class Randomizer {
  static final Random _randomInRange = Random();

  static int nextIntInRange(int min, int max) {
    int result = min + _randomInRange.nextInt(max - min);
    return result;
  }
}
