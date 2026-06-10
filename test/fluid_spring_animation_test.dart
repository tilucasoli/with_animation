import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  DoubleVectorArithmetic v(double x) => DoubleVectorArithmetic(x);
  AnimationContext<DoubleVectorArithmetic> ctx() =>
      AnimationContext<DoubleVectorArithmetic>();

  group('FluidSpringAnimation (defaults)', () {
    test('first sample is near zero offset', () {
      final a = FluidSpringAnimation();
      final r = a.animate(v(1.0), 0.0, ctx());
      expect(r, isNotNull);
      expect(r!.value, closeTo(0.0, 1e-9));
    });

    test('settles within 3s and marks logically complete', () {
      final a = FluidSpringAnimation();
      final c = ctx();
      bool settled = false;
      for (double t = 0.0; t <= 3.0; t += 1.0 / 60.0) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) {
          settled = true;
          break;
        }
      }
      expect(settled, isTrue);
      expect(c.isLogicallyComplete, isTrue);
    });

    test('approaches target over its response duration', () {
      final a = FluidSpringAnimation(response: 0.5, dampingFraction: 1.0);
      final c = ctx();
      double last = 0;
      for (double t = 0.0; t <= 3.0; t += 1.0 / 60.0) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) break;
        last = r.value;
      }
      expect(last, closeTo(1.0, 0.05));
    });
  });

  group('FluidSpringAnimation logical completion', () {
    test('flips on once time >= response', () {
      final a = FluidSpringAnimation(response: 0.5);
      final c = ctx();
      a.animate(v(1.0), 0.0, c);
      expect(c.isLogicallyComplete, isFalse);
      a.animate(v(1.0), 0.4, c);
      expect(c.isLogicallyComplete, isFalse);
      a.animate(v(1.0), 0.5, c);
      expect(c.isLogicallyComplete, isTrue);
    });
  });

  group('FluidSpringAnimation damping behavior', () {
    test('dampingFraction = 1 produces no meaningful overshoot', () {
      final a = FluidSpringAnimation(response: 0.5, dampingFraction: 1.0);
      final c = ctx();
      double maxSeen = 0;
      for (double t = 0.0; t <= 2.0; t += 1.0 / 240.0) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) break;
        if (r.value > maxSeen) maxSeen = r.value;
      }
      expect(maxSeen, lessThanOrEqualTo(1.0 + 1e-2));
    });

    test('low dampingFraction overshoots the target', () {
      final a = FluidSpringAnimation(response: 0.5, dampingFraction: 0.4);
      final c = ctx();
      double maxSeen = 0;
      for (double t = 0.0; t <= 2.0; t += 1.0 / 240.0) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) break;
        if (r.value > maxSeen) maxSeen = r.value;
      }
      expect(maxSeen, greaterThan(1.0));
    });
  });

  group('FluidSpringAnimation time backlog guard', () {
    test('huge time jump produces a finite sample without hanging', () {
      // The 1s backlog clamp caps how much sim work runs per call — without
      // it, a multi-second jump would burn through ~thousands of sim steps.
      final a = FluidSpringAnimation(response: 0.3, dampingFraction: 1.0);
      final c = ctx();
      a.animate(v(1.0), 0.0, c);
      final r = a.animate(v(1.0), 60.0, c);
      // We can't assert settle (only ~6 sim steps actually ran), but state
      // must stay finite and the logical-complete flag must fire.
      if (r != null) {
        expect(r.value.isFinite, isTrue);
      }
      expect(c.isLogicallyComplete, isTrue);
    });
  });

  group('fluidSpringDampingFraction', () {
    test('bounce 0 → 1.0 (critical damping)', () {
      expect(fluidSpringDampingFraction(0.0), closeTo(1.0, 1e-12));
    });
    test('bounce 0.15 → 0.85 (snappy preset)', () {
      expect(fluidSpringDampingFraction(0.15), closeTo(0.85, 1e-12));
    });
    test('bounce 0.3 → 0.7 (bouncy preset)', () {
      expect(fluidSpringDampingFraction(0.3), closeTo(0.7, 1e-12));
    });
    test('negative bounce → overdamped (>1)', () {
      expect(fluidSpringDampingFraction(-0.5), closeTo(2.0, 1e-12));
    });
  });

  group('AnimationSpec convenience factories', () {
    FluidSpringAnimation base(AnimationSpec s) =>
        s.base as FluidSpringAnimation;

    test('fluidSpring wraps a FluidSpringAnimation with defaults', () {
      final s = base(AnimationSpec.fluidSpring());
      expect(s.response, closeTo(0.5, 1e-12));
      expect(s.dampingFraction, closeTo(0.825, 1e-12));
      expect(s.blendDuration, closeTo(0.0, 1e-12));
    });

    test('smooth defaults to dampingFraction 1', () {
      final s = base(AnimationSpec.smooth());
      expect(s.response, closeTo(0.5, 1e-12));
      expect(s.dampingFraction, closeTo(1.0, 1e-12));
    });

    test('snappy adds 0.15 bounce', () {
      final s = base(AnimationSpec.snappy());
      expect(s.dampingFraction, closeTo(0.85, 1e-12));
    });

    test('bouncy adds 0.3 bounce', () {
      final s = base(AnimationSpec.bouncy());
      expect(s.dampingFraction, closeTo(0.7, 1e-12));
    });

    test('interactiveSpring uses short response and blend duration', () {
      final s = base(AnimationSpec.interactiveSpring());
      expect(s.response, closeTo(0.15, 1e-12));
      expect(s.dampingFraction, closeTo(0.86, 1e-12));
      expect(s.blendDuration, closeTo(0.25, 1e-12));
    });
  });
}
