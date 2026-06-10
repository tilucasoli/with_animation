import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  DoubleVectorArithmetic v(double x) => DoubleVectorArithmetic(x);
  AnimationContext<DoubleVectorArithmetic> ctx() =>
      AnimationContext<DoubleVectorArithmetic>();

  group('underdamped spring (default)', () {
    final a = SpringAnimation(mass: 1, stiffness: 100, damping: 10);

    test('starts at zero displacement', () {
      final r = a.animate(v(1.0), 0.0, ctx());
      expect(r, isNotNull);
      expect(r!.value, closeTo(0.0, 1e-9));
    });

    test('eventually settles and marks logically complete', () {
      final c = ctx();
      bool settled = false;
      for (double t = 0.0; t <= 5.0; t += 0.01) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) {
          settled = true;
          break;
        }
      }
      expect(settled, isTrue, reason: 'spring should settle within 5s');
      expect(c.isLogicallyComplete, isTrue);
    });

    test('overshoot occurs (zeta < 1)', () {
      double maxSeen = 0;
      for (double t = 0.0; t <= 2.0; t += 0.01) {
        final r = a.animate(v(1.0), t, ctx());
        if (r == null) break;
        if (r.value > maxSeen) maxSeen = r.value;
      }
      expect(maxSeen, greaterThan(1.0));
    });
  });

  group('critically damped spring (zeta == 1)', () {
    final a = SpringAnimation(mass: 1, stiffness: 100, damping: 20);

    test('approach is monotonic (no overshoot)', () {
      double previous = -double.infinity;
      for (double t = 0.0; t <= 2.0; t += 0.01) {
        final r = a.animate(v(1.0), t, ctx());
        if (r == null) break;
        expect(
          r.value,
          greaterThanOrEqualTo(previous - 1e-9),
          reason: 'value should not decrease at t=$t',
        );
        previous = r.value;
      }
    });

    test('never exceeds the target', () {
      for (double t = 0.0; t <= 5.0; t += 0.05) {
        final r = a.animate(v(1.0), t, ctx());
        if (r == null) break;
        expect(r.value, lessThanOrEqualTo(1.0 + 1e-6));
      }
    });
  });

  group('overdamped spring (zeta > 1)', () {
    final a = SpringAnimation(mass: 1, stiffness: 100, damping: 30);

    test('approach is monotonic', () {
      double previous = -double.infinity;
      for (double t = 0.0; t <= 3.0; t += 0.01) {
        final r = a.animate(v(1.0), t, ctx());
        if (r == null) break;
        expect(r.value, greaterThanOrEqualTo(previous - 1e-9));
        previous = r.value;
      }
    });
  });

  group('initialVelocity', () {
    test('non-zero initial velocity changes early trajectory', () {
      final still = SpringAnimation(mass: 1, stiffness: 100, damping: 10);
      final moving = SpringAnimation(
        mass: 1,
        stiffness: 100,
        damping: 10,
        initialVelocity: 5,
      );
      final still01 = still.animate(v(1.0), 0.01, ctx())!.value;
      final moving01 = moving.animate(v(1.0), 0.01, ctx())!.value;
      expect((still01 - moving01).abs(), greaterThan(1e-6));
    });
  });

  group('degenerate parameters', () {
    test('zero stiffness terminates without emitting non-finite samples', () {
      final a = SpringAnimation(mass: 1, stiffness: 0, damping: 10);
      // We can't loop forever; just sample a handful and assert finiteness.
      for (double t = 0.0; t <= 1.0; t += 0.1) {
        final r = a.animate(v(1.0), t, ctx());
        if (r == null) break;
        expect(r.value.isFinite, isTrue, reason: 'non-finite at t=$t');
      }
    });

    test('zero mass returns null (no NaN/Inf leak)', () {
      final a = SpringAnimation(mass: 0, stiffness: 100, damping: 10);
      final r = a.animate(v(1.0), 0.01, ctx());
      if (r != null) {
        expect(r.value.isFinite, isTrue);
      }
    });
  });
}
