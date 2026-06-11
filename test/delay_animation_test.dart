import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  AnimatableDouble v(double x) => AnimatableDouble(x);
  AnimationContext<AnimatableDouble> ctx() =>
      AnimationContext<AnimatableDouble>();

  group('DelayAnimation', () {
    test('returns zero progress during the delay window', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final delayed = DelayAnimation(
        base: base,
        delay: const Duration(milliseconds: 500),
      );
      // Before delay: no progress along the interval.
      expect(delayed.animate(v(1.0), 0.0, ctx())!.value, 0.0);
      expect(delayed.animate(v(1.0), 0.25, ctx())!.value, 0.0);
      // Edge: at exactly the delay, the base starts at t = 0.
      expect(delayed.animate(v(1.0), 0.5, ctx())!.value, 0.0);
    });

    test('shifts the base timeline by the delay', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final delayed = DelayAnimation(
        base: base,
        delay: const Duration(milliseconds: 500),
      );
      // 0.5s past the delay edge → base at t = 0.5 → value 0.5.
      expect(delayed.animate(v(1.0), 1.0, ctx())!.value, closeTo(0.5, 1e-9));
      // 1s past the delay → base completes.
      expect(delayed.animate(v(1.0), 1.6, ctx()), isNull);
    });

    test('zero delay is a no-op pass-through', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final delayed = DelayAnimation(base: base, delay: Duration.zero);
      for (final t in [0.0, 0.25, 0.5, 0.75]) {
        expect(
          delayed.animate(v(1.0), t, ctx())!.value,
          closeTo(base.animate(v(1.0), t, ctx())!.value, 1e-9),
        );
      }
    });

    test('Animations.delay() exposes the modifier on the public API', () {
      final spec = Animations.linear(
        duration: const Duration(seconds: 1),
      ).delay(const Duration(milliseconds: 500));
      expect(spec.base, isA<DelayAnimation>());
      // Before delay → zero progress.
      expect(spec.base.animate(v(1.0), 0.25, ctx())!.value, 0.0);
      // After delay → progressing.
      expect(
        spec.base.animate(v(1.0), 1.0, ctx())!.value,
        closeTo(0.5, 1e-9),
      );
    });
  });
}
