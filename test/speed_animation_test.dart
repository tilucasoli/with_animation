import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  AnimatableDouble v(double x) => AnimatableDouble(x);
  AnimationContext<AnimatableDouble> ctx() =>
      AnimationContext<AnimatableDouble>();

  group('SpeedAnimation', () {
    test('speed = 2 finishes in half the wall-clock time', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final fast = SpeedAnimation(base: base, speed: 2.0);
      // At real time 0.25, the base sees t=0.5 → value 0.5.
      expect(fast.animate(v(1.0), 0.25, ctx())!.value, closeTo(0.5, 1e-9));
      // Base completes at real time 0.5.
      expect(fast.animate(v(1.0), 0.6, ctx()), isNull);
    });

    test('speed = 0.5 takes twice as long', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final slow = SpeedAnimation(base: base, speed: 0.5);
      // At real time 1.0, base sees t=0.5 → value 0.5.
      expect(slow.animate(v(1.0), 1.0, ctx())!.value, closeTo(0.5, 1e-9));
      // Still going at real time 1.5.
      expect(slow.animate(v(1.0), 1.5, ctx()), isNotNull);
      // Base completes at real time 2.0.
      expect(slow.animate(v(1.0), 2.1, ctx()), isNull);
    });

    test('speed = 1 is a no-op pass-through', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final same = SpeedAnimation(base: base, speed: 1.0);
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(
          same.animate(v(1.0), t, ctx())!.value,
          closeTo(base.animate(v(1.0), t, ctx())!.value, 1e-9),
        );
      }
    });

    test('speed = 0 freezes at the starting value', () {
      final base = BezierAnimation.linear(const Duration(seconds: 1));
      final frozen = SpeedAnimation(base: base, speed: 0.0);
      expect(frozen.animate(v(1.0), 0.0, ctx())!.value, closeTo(0.0, 1e-9));
      expect(frozen.animate(v(1.0), 10.0, ctx())!.value, closeTo(0.0, 1e-9));
    });
  });

  group('AnimationSpec.speed modifier', () {
    test('wraps the base into a SpeedAnimation', () {
      final spec = Animations.linear().speed(3.0);
      expect(spec.base, isA<SpeedAnimation>());
      expect((spec.base as SpeedAnimation).speed, 3.0);
    });

    test('chains with repeatCount', () {
      final spec = Animations.linear(
        duration: const Duration(seconds: 1),
      ).speed(2.0).repeatCount(2);
      expect(spec.base, isA<RepeatAnimation>());
      final r = spec.base as RepeatAnimation;
      expect(r.base, isA<SpeedAnimation>());
    });
  });
}
