import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  AnimatableDouble v(double x) => AnimatableDouble(x);
  AnimationContext<AnimatableDouble> ctx() =>
      AnimationContext<AnimatableDouble>();

  group('DelayAnimation', () {
    test('returns zero progress while time < delay', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final delayed = DelayAnimation(
        base: base,
        delay: const Duration(milliseconds: 500),
      );
      expect(delayed.animate(v(1.0), 0.0, ctx())!.value, equals(0.0));
      expect(delayed.animate(v(1.0), 0.25, ctx())!.value, equals(0.0));
      expect(delayed.animate(v(1.0), 0.5, ctx())!.value, equals(0.0));
      expect(delayed.animate(v(1.0), 0.75, ctx())!.value, isNot(equals(0.0)));
    });

    test('starts the base animation at time == delay', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final delayed = DelayAnimation(
        base: base,
        delay: const Duration(milliseconds: 500),
      );
      // At real time 0.5, base sees t=0 → value 0.
      expect(delayed.animate(v(1.0), 0.5, ctx())!.value, equals(0.0));
      // At real time 1.0, base sees t=0.5 → value 0.5.
      expect(delayed.animate(v(1.0), 1.0, ctx())!.value, equals(0.5));
      // At real time 1.25, base sees t=0.75 → value 0.75.
      expect(delayed.animate(v(1.0), 1.25, ctx())!.value, equals(0.75));
    });

    test('completes delay + base duration later', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final delayed = DelayAnimation(
        base: base,
        delay: const Duration(milliseconds: 500),
      );
      // Still running just before delay + duration.
      expect(delayed.animate(v(1.0), 1.49, ctx()), isNotNull);
      // Completes after delay + duration.
      expect(delayed.animate(v(1.0), 1.6, ctx()), isNull);
    });
  });

  group('Animations.delay modifier', () {
    test('wraps the base into a DelayAnimation', () {
      final spec = Animations.linear().delay(const Duration(milliseconds: 250));
      expect(spec.base, isA<DelayAnimation>());
      expect(
        (spec.base as DelayAnimation).delay,
        const Duration(milliseconds: 250),
      );
    });

    test('chains with speed', () {
      final spec = Animations.linear(
        duration: const Duration(seconds: 1),
      ).delay(const Duration(milliseconds: 500)).speed(2.0);
      expect(spec.base, isA<SpeedAnimation>());
      final s = spec.base as SpeedAnimation;
      expect(s.base, isA<DelayAnimation>());
    });
  });
}
