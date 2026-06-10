import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  AnimatableDouble v(double x) => AnimatableDouble(x);
  AnimationContext<AnimatableDouble> ctx() =>
      AnimationContext<AnimatableDouble>();

  group('RepeatAnimation (no autoreverse)', () {
    RepeatAnimation make(int count) => RepeatAnimation(
      base: BezierAnimation.linear(const Duration(seconds: 1)),
      repeatCount: count.toDouble(),
      autoreverses: false,
    );

    test('first cycle interpolates like the base animation', () {
      final a = make(3);
      final c = ctx();
      expect(a.animate(v(1.0), 0.0, c)!.value, closeTo(0.0, 1e-9));
      expect(a.animate(v(1.0), 0.5, c)!.value, closeTo(0.5, 1e-9));
    });

    test('second cycle restarts from zero (no reverse)', () {
      final a = make(3);
      final c = ctx();
      // Drive through cycle 1.
      for (double t = 0.0; t <= 1.0; t += 0.1) {
        a.animate(v(1.0), t, c);
      }
      // Just into cycle 2 — should be near zero again, not pinned at 1.
      final r = a.animate(v(1.0), 1.1, c)!.value;
      expect(r, lessThan(0.5));
    });

    test('returns null only after all cycles finish', () {
      final a = make(2);
      final c = ctx();
      double? doneAt;
      for (double t = 0.0; t <= 3.0; t += 0.01) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) {
          doneAt = t;
          break;
        }
      }
      expect(doneAt, isNotNull, reason: '2-cycle repeat should terminate');
      // Two 1-second cycles → must finish at or after t ≈ 2.0.
      expect(doneAt, greaterThan(1.99));
    });
  });

  group('RepeatAnimation (autoreverse)', () {
    RepeatAnimation make(int count) => RepeatAnimation(
      base: BezierAnimation.linear(const Duration(seconds: 1)),
      repeatCount: count.toDouble(),
      autoreverses: true,
    );

    test('rises to ~1, then falls back to ~0', () {
      final a = make(2);
      final c = ctx();
      final samples = <double>[];
      for (double t = 0.0; t <= 2.5; t += 0.01) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) break;
        samples.add(r.value);
      }
      final maxV = samples.reduce((x, y) => x > y ? x : y);
      expect(maxV, closeTo(1.0, 0.02));
      expect(samples.last, lessThan(0.1));
    });

    test('three cycles complete and then return null', () {
      final a = make(3);
      final c = ctx();
      double? doneAt;
      for (double t = 0.0; t <= 5.0; t += 0.01) {
        final r = a.animate(v(1.0), t, c);
        if (r == null) {
          doneAt = t;
          break;
        }
      }
      expect(doneAt, isNotNull);
      expect(doneAt, greaterThan(2.99));
    });
  });

  group('RepeatAnimation.repeatForever', () {
    test('does not terminate', () {
      final a = RepeatAnimation(
        base: BezierAnimation.linear(const Duration(seconds: 1)),
        repeatCount: double.infinity,
      );
      final c = ctx();
      for (double t = 0.0; t < 100.0; t += 0.25) {
        expect(
          a.animate(v(1.0), t, c),
          isNotNull,
          reason: 'should still be animating at t=$t',
        );
      }
    });
  });

  group('AnimationSpec modifiers', () {
    test('repeatCount wraps the base into a RepeatAnimation', () {
      final spec = Animations.linear(
        duration: const Duration(seconds: 1),
      ).repeatCount(2, autoreverses: false);
      expect(spec.base, isA<RepeatAnimation>());
      final r = spec.base as RepeatAnimation;
      expect(r.repeatCount, 2.0);
      expect(r.autoreverses, isFalse);
    });

    test('repeatForever uses infinity', () {
      final spec = Animations.linear().repeatForever();
      expect(spec.base, isA<RepeatAnimation>());
      expect((spec.base as RepeatAnimation).repeatCount, double.infinity);
    });
  });

  group('edge cases', () {
    test('zero repeats returns null immediately', () {
      final a = RepeatAnimation(
        base: BezierAnimation.linear(const Duration(seconds: 1)),
        repeatCount: 0,
      );
      expect(a.animate(v(1.0), 0.0, ctx()), isNull);
    });
  });
}
