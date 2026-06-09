import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

class _Constant extends CustomAnimation {
  final double fraction;
  _Constant(this.fraction);

  @override
  T? animate<T extends VectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> context,
  ) =>
      value.scale(fraction);
}

void main() {
  group('CustomAnimation', () {
    test('default shouldMerge returns false', () {
      final a = _Constant(0.5);
      final b = _Constant(1.0);
      final result = a.shouldMerge<AnimatableDouble>(
        b,
        AnimatableDouble(1.0),
        0.0,
        AnimationContext<AnimatableDouble>(),
      );
      expect(result, isFalse);
    });

    test('animate scales the value as expected', () {
      final a = _Constant(0.25);
      final out = a.animate<AnimatableDouble>(
        AnimatableDouble(8.0),
        0.0,
        AnimationContext<AnimatableDouble>(),
      );
      expect(out!.value, 2.0);
    });
  });

  group('AnimationContext / AnimationState', () {
    test('get returns default before set', () {
      final s = AnimationState();
      expect(s.get<int>(7), 7);
    });

    test('set then get returns the stored value', () {
      final s = AnimationState();
      s.set<int>(42);
      expect(s.get<int>(0), 42);
    });

    test('different types share no storage', () {
      final s = AnimationState();
      s.set<int>(1);
      s.set<String>('hello');
      expect(s.get<int>(0), 1);
      expect(s.get<String>(''), 'hello');
    });

    test('context defaults isLogicallyComplete to false', () {
      final c = AnimationContext<AnimatableDouble>();
      expect(c.isLogicallyComplete, isFalse);
    });
  });
}
